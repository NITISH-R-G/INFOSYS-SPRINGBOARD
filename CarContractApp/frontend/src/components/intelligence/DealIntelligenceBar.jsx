import React, { useState } from 'react';
import './Intelligence.css';

const DealIntelligenceBar = ({ analysisData }) => {
    const [expanded, setExpanded] = useState(false);

    // Mock data if analysisData is missing
    const dealScore = analysisData?.fairness_score || 78;
    const monthly = 540; // Mock
    const marketDelta = "-$32"; // Mock

    return (
        <div className={`deal-intelligence-bar glass-pill-top ${expanded ? 'expanded' : ''}`} onClick={() => setExpanded(!expanded)}>
            {/* Collapsed State: Horizontal Pills */}
            <div className="deal-summary-row">
                <div className="deal-score-pill">
                    <span className="score-label">DEAL SCORE</span>
                    <span className={`score-value ${dealScore > 75 ? 'good' : 'bad'}`}>{dealScore}</span>
                </div>

                <div className="divider-vertical"></div>

                <div className="market-stat">
                    <span className="stat-label">MARKET POS.</span>
                    <span className="stat-value text-green">{marketDelta} /mo</span>
                </div>

                <div className="divider-vertical"></div>

                <div className="cost-breakdown-preview">
                    <span className="stat-value">${monthly}</span>
                    <span className="stat-unit">/mo</span>
                </div>

                <div className="expand-indicator">
                    <span className="chevron">▼</span>
                </div>
            </div>

            {/* Expanded State: Visuals */}
            {expanded && (
                <div className="deal-deep-dive">
                    <div className="cost-timeline-viz">
                        <h4>5-Year Cost Projection</h4>
                        <div className="mock-graph-line"></div>
                        {/* Placeholder for SVG graph */}
                    </div>
                </div>
            )}
        </div>
    );
};

export default DealIntelligenceBar;
