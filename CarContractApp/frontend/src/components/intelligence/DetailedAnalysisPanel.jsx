import React, { useState } from 'react';
import './Intelligence.css';

const DetailedAnalysisPanel = ({ detailedAnalysis }) => {
    const [expandedSections, setExpandedSections] = useState({});

    if (!detailedAnalysis) return null;

    const toggleSection = (key) => {
        setExpandedSections(prev => ({
            ...prev,
            [key]: !prev[key]
        }));
    };

    const formatLabel = (key) => {
        return key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
    };

    const formatValue = (value) => {
        if (!value || value === 'Not Mentioned') return <span className="value-missing">Not Mentioned</span>;
        return <span className="value-present">{value}</span>;
    };

    const renderSection = (key, data) => {
        if (!data) return null;

        // Filter out internal fields like risk_flags to show only content fields first
        const fields = Object.entries(data).filter(([k]) => k !== 'risk_flags');
        const risks = data.risk_flags || [];
        const isExpanded = expandedSections[key];

        // Count non-empty fields to show summary
        const presentFields = fields.filter(([_, v]) => v && v !== 'Not Mentioned').length;

        return (
            <div key={key} className={`analysis-section ${isExpanded ? 'expanded' : ''}`}>
                <div className="analysis-section-header" onClick={() => toggleSection(key)}>
                    <div className="header-left">
                        <span className="section-title">{formatLabel(key)}</span>
                        {risks.length > 0 && <span className="risk-badge">{risks.length} Risk{risks.length > 1 ? 's' : ''}</span>}
                    </div>
                    <div className="header-right">
                        <span className="field-count">{presentFields}/{fields.length} Found</span>
                        <span className="chevron">{isExpanded ? '▲' : '▼'}</span>
                    </div>
                </div>

                {isExpanded && (
                    <div className="analysis-section-content">
                        {risks.length > 0 && (
                            <div className="section-risks">
                                {risks.map((risk, idx) => (
                                    <div key={idx} className="risk-item">
                                        <div className="risk-icon">⚠️</div>
                                        <div className="risk-details">
                                            <div className="risk-clause">"{risk.clause}"</div>
                                            <div className="risk-reason">{risk.reason}</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}

                        <div className="section-fields">
                            {fields.map(([fieldKey, fieldValue]) => (
                                <div key={fieldKey} className="field-row">
                                    <span className="field-label">{formatLabel(fieldKey)}</span>
                                    <div className="field-value">{formatValue(fieldValue)}</div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        );
    };

    // Define the order of sections
    const sections = [
        'vehicle_details',
        'lease_payment_terms',
        'lease_duration',
        'mileage_usage_limits',
        'maintenance_responsibilities',
        'insurance_requirements',
        'damage_and_wear_conditions',
        'early_termination_terms',
        'ownership_terms',
        'usage_restrictions',
        'default_and_legal_clauses',
        'end_of_lease_process'
    ];

    return (
        <div className="detailed-analysis-panel">
            <h4 className="panel-main-title">Full Contract Analysis</h4>
            <div className="analysis-accordion">
                {sections.map(sectionKey => renderSection(sectionKey, detailedAnalysis[sectionKey]))}
            </div>
        </div>
    );
};

export default DetailedAnalysisPanel;
