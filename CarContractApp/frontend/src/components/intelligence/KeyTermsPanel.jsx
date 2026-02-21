import React from 'react';
import { formatCurrency } from '../../utils/localization';
import './Intelligence.css';

const KeyTermsPanel = ({ analysisData, currencyCode, onTermClick }) => {
    // Mock extraction data if not present in analysis
    const sla = analysisData?.sla_data || {};

    // Calculate total cost if possible
    let totalCost = null;
    if (sla.monthly_payment && sla.term_months && sla.down_payment) {
        totalCost = (sla.monthly_payment * sla.term_months) + sla.down_payment;
    }

    const terms = [
        {
            key: 'apr',
            label: 'APR',
            value: sla.apr ? `${sla.apr}%` : 'N/A',
            confidence: sla.apr ? 'high' : 'low'
        },
        {
            key: 'monthly_payment',
            label: 'Monthly',
            value: sla.monthly_payment ? formatCurrency(sla.monthly_payment, null, currencyCode) : 'N/A',
            confidence: sla.monthly_payment ? 'high' : 'low'
        },
        {
            key: 'term_months',
            label: 'Duration',
            value: sla.term_months ? `${sla.term_months} Months` : 'N/A',
            confidence: sla.term_months ? 'high' : 'low'
        },
        {
            key: 'down_payment',
            label: 'Down Pmt',
            value: sla.down_payment ? formatCurrency(sla.down_payment, null, currencyCode) : 'N/A',
            confidence: sla.down_payment ? 'high' : 'low'
        },
        {
            key: 'total_cost',
            label: 'Total Cost',
            value: totalCost ? formatCurrency(totalCost, null, currencyCode) : 'Est. N/A',
            confidence: totalCost ? 'medium' : 'low'
        },
    ];

    const getConfidenceClass = (level) => {
        switch (level) {
            case 'high': return 'conf-high';
            case 'medium': return 'conf-medium';
            case 'low': return 'conf-low';
            default: return 'conf-medium';
        }
    };

    return (
        <div className="key-terms-panel">
            <h4 className="section-label">Financial Terms (SLA)</h4>
            <div className="terms-grid">
                {terms.map((term) => (
                    <div
                        key={term.key}
                        className="term-chip"
                        onClick={() => onTermClick && onTermClick(term.key)}
                    >
                        <span className="term-label">{term.label}</span>
                        <div className="term-value-row">
                            <span className="term-value">{term.value}</span>
                            <div className={`conf-dot ${getConfidenceClass(term.confidence)}`} title={`${term.confidence} confidence`}></div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default KeyTermsPanel;
