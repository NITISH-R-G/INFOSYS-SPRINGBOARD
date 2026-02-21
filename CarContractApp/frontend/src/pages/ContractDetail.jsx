import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import api from '../services/api';
import PDFViewer from '../components/PDFViewer';
import ErrorBoundary from '../components/ErrorBoundary';
import './ContractDetail.css';

// Intelligence Components
import AlternativeCarsStrip from '../components/intelligence/AlternativeCarsStrip';
import NegotiationSheet from '../components/intelligence/NegotiationSheet';
import ScenarioFAB from '../components/intelligence/ScenarioFAB';
import VehicleRiskPanel from '../components/intelligence/VehicleRiskPanel';
import ContractInsightsPanel from '../components/intelligence/ContractInsightsPanel';
import KeyTermsPanel from '../components/intelligence/KeyTermsPanel';
import DetailedAnalysisPanel from '../components/intelligence/DetailedAnalysisPanel';

export default function ContractDetail() {
    const { id } = useParams();
    const [contract, setContract] = useState(null);
    const [analysis, setAnalysis] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Layout State
    const [showLeftPanel, setShowLeftPanel] = useState(true);
    const [showRightPanel, setShowRightPanel] = useState(true);
    const [activeFlag, setActiveFlag] = useState(null);
    const [activeFlagIndex, setActiveFlagIndex] = useState(null);
    const [showAlternatives, setShowAlternatives] = useState(false);
    const [autoExpandNegotiation, setAutoExpandNegotiation] = useState(false);

    useEffect(() => {
        fetchContractDetails();
    }, [id]);

    const fetchContractDetails = async () => {
        try {
            const data = await api.getContract(id);
            setContract(data);
            if (data.analysis) {
                setAnalysis(data.analysis);
            } else {
                try {
                    const analysisResult = await api.analyzeContract(id);
                    setAnalysis(analysisResult);
                } catch (e) {
                    console.warn("Analysis not ready yet", e);
                }
            }
        } catch (err) {
            console.error("Error fetching contract:", err);
            setError("Failed to load contract details.");
        } finally {
            setLoading(false);
        }
    };

    const handleFlagClick = (index, flag) => {
        setActiveFlagIndex(index);
        setActiveFlag(flag);
        setAutoExpandNegotiation(true);
        if (!showRightPanel) setShowRightPanel(true);
    };

    // Extract currency code from analysis SLA data, default to USD if missing
    const currencyCode = analysis?.sla_data?.currency_code || 'USD';

    if (loading) return (
        <div className="immersive-page loading-state">
            <div className="glass-loader">
                <div className="spinner"></div>
                <span>Loading Intelligence...</span>
            </div>
        </div>
    );

    return (
        <ErrorBoundary>
            <div className="immersive-page">
                {/* LAYER 0: PDF CANVAS */}
                <div className="pdf-layer">
                    {contract ? (
                        <PDFViewer
                            contractId={id}
                            redFlags={analysis?.red_flags || []}
                            filename={contract.filename}
                            activeFlagIndex={activeFlagIndex}
                            onFlagClick={handleFlagClick}
                        />
                    ) : (
                        <div className="empty-pdf-placeholder">
                            <div className="glass-message">No Contract Loaded</div>
                        </div>
                    )}
                </div>

                {/* LAYER 1: HUD & OVERLAYS */}

                {/* Top Bar */}
                <div className="glass-topbar">
                    <div className="topbar-left">
                        <button className="glass-icon-btn" onClick={() => window.history.back()}>←</button>
                        <div className="contract-title">
                            <h1>{contract?.filename || 'Contract'}</h1>
                            <span className="meta-badge">{contract?.contract_type || 'Loan'}</span>
                        </div>
                    </div>
                </div>

                {/* Smart Alternatives - Collapsible */}
                <AlternativeCarsStrip
                    isExpanded={showAlternatives}
                    onToggle={setShowAlternatives}
                    currencyCode={currencyCode}
                />

                {/* Left Panel: Vehicle Summary & Key Terms */}
                <div className={`glass-panel-left ${showLeftPanel ? '' : 'closed'}`}>
                    <div className="panel-toggle" onClick={() => setShowLeftPanel(!showLeftPanel)}>
                        {showLeftPanel ? '‹' : '›'}
                    </div>
                    <div className="panel-content scrollable">
                        <KeyTermsPanel
                            analysisData={analysis}
                            currencyCode={currencyCode}
                            onTermClick={(key) => console.log('Highlight term:', key)}
                        />

                        <div className="divider"></div>

                        <VehicleRiskPanel
                            fairnessScore={analysis?.fairness_score}
                            vehicleData={contract?.vehicle_data}
                        />

                        <div className="divider"></div>

                        <DetailedAnalysisPanel
                            detailedAnalysis={analysis?.detailed_analysis}
                        />
                    </div>
                </div>

                {/* Right Panel: Analysis Insights */}
                <div className={`glass-panel-right ${showRightPanel ? '' : 'closed'}`}>
                    <div className="panel-toggle" onClick={() => setShowRightPanel(!showRightPanel)}>
                        {showRightPanel ? '›' : '‹'}
                    </div>
                    <div className="panel-content scrollable">
                        <ContractInsightsPanel
                            redFlags={analysis?.red_flags || []}
                            activeFlagIndex={activeFlagIndex}
                            onFlagClick={handleFlagClick}
                        />
                    </div>
                </div>

                {/* LAYER 2: BOTTOM ACTIONS */}
                <NegotiationSheet
                    autoExpand={autoExpandNegotiation}
                    activeClause={activeFlag}
                    nearbyAlternatives={[]} // would come from API
                />

                <ScenarioFAB onClick={() => console.log('Open Simulation')} />
            </div>
        </ErrorBoundary>
    );
}
