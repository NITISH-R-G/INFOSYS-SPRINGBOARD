import React, { useState, useEffect } from 'react';
import './Intelligence.css';

const NegotiationSheet = ({ autoExpand, activeClause, nearbyAlternatives }) => {
    const [isOpen, setIsOpen] = useState(false);

    // Auto-expand when clause is tapped or alternatives are relevant
    useEffect(() => {
        if (autoExpand) {
            setIsOpen(true);
        }
    }, [autoExpand]);

    const leverageText = nearbyAlternatives?.length > 0
        ? `${nearbyAlternatives.length} alternatives nearby could save you money`
        : 'Analyze the contract for negotiation points';

    return (
        <div className={`negotiation-sheet-clean ${isOpen ? 'open' : 'collapsed'}`}>
            <div className="sheet-handle-clean" onClick={() => setIsOpen(!isOpen)}>
                <div className="handle-bar"></div>
                <div className="handle-content">
                    <span className="handle-title">AI Negotiation Assistant</span>
                    {!isOpen && (
                        <span className="handle-hint">{leverageText}</span>
                    )}
                </div>
            </div>

            {isOpen && (
                <div className="sheet-content-clean">
                    {activeClause ? (
                        <div className="active-clause-context">
                            <span className="context-label">Regarding:</span>
                            <p className="context-clause">{activeClause.title}</p>
                        </div>
                    ) : (
                        <div className="suggestion-prompt">
                            <p>Tap any highlighted clause in the contract to get negotiation suggestions.</p>
                        </div>
                    )}

                    <div className="ai-suggestions">
                        <div className="suggestion-item">
                            <div className="suggestion-icon">💡</div>
                            <div className="suggestion-text">
                                <p>Based on the "As Is" clause, consider requesting a 3-day inspection window before finalizing.</p>
                            </div>
                            <button className="suggestion-action">Use This</button>
                        </div>

                        {nearbyAlternatives?.length > 0 && (
                            <div className="leverage-card">
                                <span className="leverage-label">Leverage Point</span>
                                <p>Similar vehicles available within 15km at lower prices. Use this to negotiate down.</p>
                            </div>
                        )}
                    </div>

                    <div className="sheet-actions">
                        <button className="action-btn-secondary">Generate Email</button>
                        <button className="action-btn-primary">Get More Tips</button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default NegotiationSheet;
