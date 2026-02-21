import { useState, useCallback, useEffect, useRef } from 'react'
import { Document, Page, pdfjs } from 'react-pdf'
import './PDFViewer.css'

// Valid Vite Worker Configuration
// This avoids external UNPKG dependencies which might fail and crash the app
import 'react-pdf/dist/Page/AnnotationLayer.css';
import 'react-pdf/dist/Page/TextLayer.css';

// Set worker source to UNPKG for stability matches installed version
pdfjs.GlobalWorkerOptions.workerSrc = `//unpkg.com/pdfjs-dist@${pdfjs.version}/build/pdf.worker.min.mjs`;

export default function PDFViewer({ contractId, redFlags = [], filename, activeFlagIndex, onFlagClick }) {
    const [numPages, setNumPages] = useState(null)
    const [scale, setScale] = useState(1.2)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)
    const pageRefs = useRef({})

    // Popup state for floating glass sheet
    const [activePopup, setActivePopup] = useState(null) // { x, y, flag }

    const pdfUrl = `http://localhost:8000/files/${contractId}`

    // Effect to jump to page when active flag changes
    useEffect(() => {
        if (activeFlagIndex !== null && redFlags[activeFlagIndex]?.coordinates?.length > 0) {
            const firstMatch = redFlags[activeFlagIndex].coordinates[0]
            if (firstMatch && firstMatch.page) {
                const pageEl = pageRefs.current[firstMatch.page]
                if (pageEl) {
                    pageEl.scrollIntoView({ behavior: 'smooth', block: 'center' })
                }
            }
        }
    }, [activeFlagIndex, redFlags])

    const onDocumentLoadSuccess = useCallback(({ numPages }) => {
        setNumPages(numPages)
        setLoading(false)
    }, [])

    const onDocumentLoadError = useCallback((error) => {
        console.error('PDF load error:', error)
        setError('Failed to load PDF. The file may be an image or corrupted.')
        setLoading(false)
    }, [])

    const zoomIn = () => setScale(prev => Math.min(prev + 0.2, 3.0))
    const zoomOut = () => setScale(prev => Math.max(prev - 0.2, 0.5))

    const handleHighlightClick = (e, flag, index) => {
        e.stopPropagation();
        // Check bounds
        const rect = e.target.getBoundingClientRect();

        setActivePopup({
            x: rect.left + (rect.width / 2),
            y: rect.top,
            flag: flag
        });

        if (onFlagClick) {
            onFlagClick(index, flag);
        }
    };

    const closePopup = () => setActivePopup(null);

    // Get risk level color for highlights
    const getRiskColorClass = (level) => {
        switch (level?.toLowerCase()) {
            case 'high': return 'highlight-high'
            case 'medium': return 'highlight-medium'
            case 'low': return 'highlight-low'
            default: return 'highlight-medium'
        }
    }

    return (
        <div className="pdf-immersive-container" onClick={closePopup}>
            {/* Main Scrollable Canvas */}
            <div className="pdf-canvas-area">
                {loading && !error && (
                    <div className="pdf-immersive-loading">
                        <div className="spinner"></div>
                        <span>Loading document...</span>
                    </div>
                )}

                {error && (
                    <div className="pdf-error">
                        <i className="ph-fill ph-file-x"></i>
                        <span>{error}</span>
                        {/* Fallback Image if PDF fails */}
                        <img
                            src={pdfUrl}
                            alt={filename}
                            style={{ maxWidth: '100%', maxHeight: '500px', objectFit: 'contain' }}
                            onError={() => { }}
                        />
                    </div>
                )}

                {!error && (
                    <Document
                        file={pdfUrl}
                        onLoadSuccess={onDocumentLoadSuccess}
                        onLoadError={onDocumentLoadError}
                        loading={null}
                        className="pdf-document"
                    >
                        {Array.from(new Array(numPages || 0), (_, index) => {
                            const pageNum = index + 1
                            return (
                                <div
                                    key={`page-${pageNum}`}
                                    className="pdf-page-wrapper"
                                    ref={el => pageRefs.current[pageNum] = el}
                                >
                                    <Page
                                        pageNumber={pageNum}
                                        scale={scale}
                                        renderTextLayer={false}
                                        renderAnnotationLayer={false}
                                        className="pdf-page shadow-depth"
                                    />

                                    {/* Highlights Overlay */}
                                    <div className="highlights-layer">
                                        {redFlags.map((flag, flagIndex) => {
                                            if (!flag.coordinates) return null

                                            // Only render coordinates for this page
                                            return flag.coordinates
                                                .filter(coord => coord.page === pageNum)
                                                .map((coord, coordIndex) => {
                                                    const [x0, y0, x1, y1] = coord.rect
                                                    const width = (x1 - x0) * scale
                                                    const height = (y1 - y0) * scale
                                                    const left = x0 * scale
                                                    const top = y0 * scale
                                                    const isActive = activeFlagIndex === flagIndex

                                                    return (
                                                        <div
                                                            key={`${flagIndex}-${coordIndex}`}
                                                            className={`pdf-highlight ${getRiskColorClass(flag.risk_level)} ${isActive ? 'active' : ''}`}
                                                            style={{
                                                                left: `${left}px`,
                                                                top: `${top}px`,
                                                                width: `${width}px`,
                                                                height: `${height}px`
                                                            }}
                                                            onClick={(e) => handleHighlightClick(e, flag, flagIndex)}
                                                            title={flag.title}
                                                        />
                                                    )
                                                })
                                        })}
                                    </div>
                                </div>
                            )
                        })}
                    </Document>
                )}
            </div>

            {/* Floating Glass Settings Toolbar (Bottom Center) */}
            <div className="pdf-floating-toolbar" onClick={e => e.stopPropagation()}>
                <div className="toolbar-group">
                    <span className="page-indicator">
                        {numPages ? `${numPages} Pages` : 'Loading...'}
                    </span>
                </div>
                <div className="toolbar-divider"></div>
                <div className="toolbar-group">
                    <button onClick={zoomOut} className="tool-btn"><i className="ph ph-minus">-</i></button>
                    <span className="zoom-val">{Math.round(scale * 100)}%</span>
                    <button onClick={zoomIn} className="tool-btn"><i className="ph ph-plus">+</i></button>
                </div>
            </div>

            {/* Floating Glass Info Sheet (Overlay) */}
            {activePopup && (
                <div
                    className="floating-glass-sheet"
                    style={{
                        left: activePopup.x,
                        top: activePopup.y - 20,
                    }}
                    onClick={e => e.stopPropagation()}
                >
                    <div className="sheet-header">
                        <span className={`risk-badge ${activePopup.flag.risk_level?.toLowerCase()}`}>
                            {activePopup.flag.risk_level} Risk
                        </span>
                        <button className="close-btn" onClick={closePopup}>×</button>
                    </div>
                    <h4>{activePopup.flag.title}</h4>
                    <p className="sheet-desc">{activePopup.flag.description}</p>

                    <div className="sheet-actions">
                        <button className="action-btn">
                            <span>Negotiate This</span>
                        </button>
                    </div>
                </div>
            )}
        </div>
    )
}
