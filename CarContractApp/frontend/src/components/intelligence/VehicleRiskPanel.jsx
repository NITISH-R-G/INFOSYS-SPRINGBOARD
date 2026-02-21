import React from 'react';
import './Intelligence.css';

const VehicleRiskPanel = ({ fairnessScore, vehicleData }) => {
    // Mock/fallback data
    const carName = vehicleData?.model || "2024 Honda City";
    const carTrim = vehicleData?.trim || "V CVT Petrol";
    const score = fairnessScore || null;

    // Grouped data
    const ownershipQuality = [
        { label: 'Reliability', value: 'High', status: 'good' },
        { label: 'Resale Value', value: 'Strong', status: 'good' },
    ];

    const riskIndicators = [
        { label: 'Active Recalls', value: '0', status: 'good' },
        { label: 'Depreciation', value: 'Average', status: 'neutral' },
    ];

    const getScoreColor = (s) => {
        if (!s) return 'neutral';
        if (s >= 75) return 'good';
        if (s >= 50) return 'fair';
        return 'poor';
    };

    return (
        <div className="vehicle-panel-clean">
            {/* Car Identity - Compact */}
            <div className="car-identity-compact">
                <div className="car-icon-minimal">🚗</div>
                <div className="car-name-block">
                    <h3>{carName}</h3>
                    <span className="car-trim-label">{carTrim}</span>
                </div>
            </div>

            {/* Score Ring - Compact */}
            <div className="score-ring-compact">
                <div className={`ring-visual ${getScoreColor(score)}`}>
                    <span className="ring-value">{score || '—'}</span>
                </div>
                <div className="ring-context">
                    <span className="ring-title">Deal Quality</span>
                    <span className="ring-subtitle">
                        {score >= 75 ? 'Fair pricing detected' :
                            score >= 50 ? 'Review recommended' :
                                score ? 'Caution advised' : 'Analyzing...'}
                    </span>
                </div>
            </div>

            <div className="section-divider"></div>

            {/* Ownership Quality Section */}
            <div className="metric-section">
                <h4 className="section-label">Ownership Quality</h4>
                <div className="metric-list">
                    {ownershipQuality.map((item, i) => (
                        <div key={i} className="metric-row">
                            <span className="metric-label">{item.label}</span>
                            <span className={`metric-value status-${item.status}`}>{item.value}</span>
                        </div>
                    ))}
                </div>
            </div>

            {/* Risk Indicators Section */}
            <div className="metric-section">
                <h4 className="section-label">Risk Indicators</h4>
                <div className="metric-list">
                    {riskIndicators.map((item, i) => (
                        <div key={i} className="metric-row">
                            <span className="metric-label">{item.label}</span>
                            <span className={`metric-value status-${item.status}`}>{item.value}</span>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default VehicleRiskPanel;
