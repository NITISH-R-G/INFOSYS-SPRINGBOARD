import React from 'react';
import './Intelligence.css';

const ContractInsightsPanel = ({ redFlags = [], onFlagClick, activeFlagIndex }) => {
    // Filter out insights with no meaningful description
    const validInsights = redFlags.filter(flag =>
        flag.description && flag.description.trim().length > 10
    );

    // Sort by severity (high first)
    const sortedInsights = [...validInsights].sort((a, b) => {
        const order = { 'high': 0, 'medium': 1, 'low': 2 };
        return (order[a.risk_level?.toLowerCase()] || 2) - (order[b.risk_level?.toLowerCase()] || 2);
    });

    const handleInsightClick = (originalIndex, flag) => {
        onFlagClick && onFlagClick(originalIndex, flag);
    };

    // Get original index for flag
    const getOriginalIndex = (flag) => redFlags.findIndex(f => f === flag);

    return (
        <div className="insights-panel-clean">
            <div className="panel-header-compact">
                <h3>Analysis Insights</h3>
                {sortedInsights.length > 0 && (
                    <span className="insight-count">{sortedInsights.length}</span>
                )}
            </div>

            {sortedInsights.length === 0 ? (
                <div className="empty-state-calm">
                    <div className="empty-icon">✓</div>
                    <h4>No Critical Issues</h4>
                    <p>This contract appears standard. No concerning clauses were detected during analysis.</p>
                </div>
            ) : (
                <div className="insight-list-clean">
                    {sortedInsights.map((flag, idx) => {
                        const originalIndex = getOriginalIndex(flag);
                        const isActive = activeFlagIndex === originalIndex;

                        return (
                            <div
                                key={idx}
                                className={`insight-item-clean ${isActive ? 'active pulse' : ''}`}
                                onClick={() => handleInsightClick(originalIndex, flag)}
                            >
                                <div className="insight-header">
                                    <span className={`severity-dot-clean ${flag.risk_level?.toLowerCase() || 'medium'}`}></span>
                                    <span className="insight-title-clean">
                                        {flag.title || 'Contract Clause'}
                                    </span>
                                </div>
                                <p className="insight-desc-clean">
                                    {flag.description.length > 100
                                        ? flag.description.substring(0, 100) + '...'
                                        : flag.description}
                                </p>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default ContractInsightsPanel;
