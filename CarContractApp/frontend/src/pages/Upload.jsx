import { useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { uploadContract, analyzeContract } from '../services/api'
import './Upload.css'

export default function Upload() {
    const [file, setFile] = useState(null)
    const [dragOver, setDragOver] = useState(false)
    const [uploading, setUploading] = useState(false)
    const [analyzing, setAnalyzing] = useState(false)
    const [uploadResult, setUploadResult] = useState(null)
    const [error, setError] = useState('')
    const fileInputRef = useRef(null)
    const navigate = useNavigate()

    const handleDragOver = (e) => {
        e.preventDefault()
        setDragOver(true)
    }

    const handleDragLeave = () => {
        setDragOver(false)
    }

    const handleDrop = (e) => {
        e.preventDefault()
        setDragOver(false)
        const droppedFile = e.dataTransfer.files[0]
        if (droppedFile) {
            validateAndSetFile(droppedFile)
        }
    }

    const handleFileSelect = (e) => {
        const selectedFile = e.target.files[0]
        if (selectedFile) {
            validateAndSetFile(selectedFile)
        }
    }

    const validateAndSetFile = (selectedFile) => {
        const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg', 'image/jpg']
        if (!allowedTypes.includes(selectedFile.type)) {
            setError('Please upload a PDF or image file (PNG, JPG)')
            return
        }
        if (selectedFile.size > 10 * 1024 * 1024) {
            setError('File size must be less than 10MB')
            return
        }
        setFile(selectedFile)
        setError('')
        setUploadResult(null)
    }

    const handleUpload = async () => {
        if (!file) return

        setUploading(true)
        setError('')

        try {
            const result = await uploadContract(file)
            setUploadResult(result)
        } catch (err) {
            setError(err.message)
        } finally {
            setUploading(false)
        }
    }

    const handleAnalyze = async () => {
        if (!uploadResult?.id) return

        setAnalyzing(true)
        setError('')

        try {
            await analyzeContract(uploadResult.id)
            navigate(`/contract/${uploadResult.id}`)
        } catch (err) {
            setError(err.message)
        } finally {
            setAnalyzing(false)
        }
    }

    const formatFileSize = (bytes) => {
        if (bytes < 1024) return bytes + ' B'
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
    }

    return (
        <div className="page">
            <div className="container">
                <div className="upload-page-header">
                    <h1>Upload Contract</h1>
                    <p className="text-muted">Upload your car lease or loan contract for AI analysis</p>
                </div>

                <div className="upload-grid">
                    {/* Upload Area */}
                    <div className="upload-section glass-panel-static">
                        <div
                            className={`upload-area ${dragOver ? 'dragover' : ''}`}
                            onDragOver={handleDragOver}
                            onDragLeave={handleDragLeave}
                            onDrop={handleDrop}
                            onClick={() => fileInputRef.current?.click()}
                        >
                            <i className="ph-light ph-cloud-arrow-up upload-icon"></i>
                            <div className="upload-text">Drag & Drop your contract</div>
                            <div className="upload-subtext">or click to browse</div>
                            <div className="upload-formats">PDF, PNG, JPG (Max 10MB)</div>
                            <input
                                type="file"
                                ref={fileInputRef}
                                onChange={handleFileSelect}
                                accept=".pdf,.png,.jpg,.jpeg"
                                hidden
                            />
                        </div>

                        {/* Selected File */}
                        {file && (
                            <div className="selected-file">
                                <div className="file-icon">
                                    <i className={`ph-fill ${file.type === 'application/pdf' ? 'ph-file-pdf' : 'ph-file-image'}`}></i>
                                </div>
                                <div className="file-info">
                                    <span className="file-name">{file.name}</span>
                                    <span className="file-size">{formatFileSize(file.size)}</span>
                                </div>
                                <button
                                    className="btn btn-icon btn-secondary"
                                    onClick={(e) => {
                                        e.stopPropagation()
                                        setFile(null)
                                        setUploadResult(null)
                                    }}
                                >
                                    <i className="ph ph-x"></i>
                                </button>
                            </div>
                        )}

                        {/* Error */}
                        {error && (
                            <div className="upload-error">
                                <i className="ph-fill ph-warning-circle"></i>
                                {error}
                            </div>
                        )}

                        {/* Actions */}
                        <div className="upload-actions">
                            {!uploadResult ? (
                                <button
                                    className="btn btn-primary btn-lg"
                                    onClick={handleUpload}
                                    disabled={!file || uploading}
                                >
                                    {uploading ? (
                                        <>
                                            <div className="spinner"></div>
                                            Uploading...
                                        </>
                                    ) : (
                                        <>
                                            <i className="ph ph-upload"></i>
                                            Upload Contract
                                        </>
                                    )}
                                </button>
                            ) : (
                                <button
                                    className="btn btn-success btn-lg"
                                    onClick={handleAnalyze}
                                    disabled={analyzing}
                                >
                                    {analyzing ? (
                                        <>
                                            <div className="spinner"></div>
                                            Analyzing...
                                        </>
                                    ) : (
                                        <>
                                            <i className="ph ph-sparkle"></i>
                                            Analyze with AI
                                        </>
                                    )}
                                </button>
                            )}
                        </div>

                        {/* Upload Success */}
                        {uploadResult && (
                            <div className="upload-success">
                                <i className="ph-fill ph-check-circle"></i>
                                <span>Contract uploaded successfully! Click "Analyze with AI" to extract terms.</span>
                            </div>
                        )}
                    </div>

                    {/* Info Panel */}
                    <div className="info-section">
                        <div className="info-card glass-panel">
                            <h3>
                                <i className="ph-fill ph-info"></i>
                                What We Extract
                            </h3>
                            <ul className="info-list">
                                <li><i className="ph ph-check"></i> Interest Rate (APR)</li>
                                <li><i className="ph ph-check"></i> Monthly Payment</li>
                                <li><i className="ph ph-check"></i> Lease/Loan Term</li>
                                <li><i className="ph ph-check"></i> Mileage Limits</li>
                                <li><i className="ph ph-check"></i> Early Termination Fees</li>
                                <li><i className="ph ph-check"></i> Hidden Fees & Charges</li>
                                <li><i className="ph ph-check"></i> Warranty Coverage</li>
                            </ul>
                        </div>

                        <div className="info-card glass-panel">
                            <h3>
                                <i className="ph-fill ph-shield-check"></i>
                                Your Privacy
                            </h3>
                            <p>Your documents are processed securely and never shared. All data is encrypted in transit and at rest.</p>
                        </div>

                        <div className="info-card glass-panel">
                            <h3>
                                <i className="ph-fill ph-lightbulb"></i>
                                Tips
                            </h3>
                            <ul className="info-list">
                                <li><i className="ph ph-arrow-right"></i> Use clear, high-resolution scans</li>
                                <li><i className="ph ph-arrow-right"></i> Include all pages of the contract</li>
                                <li><i className="ph ph-arrow-right"></i> PDF format works best</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
