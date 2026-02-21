
import React, { useState } from 'react';
import { formatCurrency, getLocationLabel } from '../../utils/localization';
import './Intelligence.css';

const AlternativeCarsStrip = ({ currentDeal, isExpanded: externalExpanded, onToggle, currencyCode }) => {
    const [internalExpanded, setInternalExpanded] = useState(false);
    const isExpanded = externalExpanded !== undefined ? externalExpanded : internalExpanded;

    // Mock data - in production, this would come from location-aware API
    const currentCarMonthly = currentDeal?.monthly || 28500;

    // Adjust mock values based on currency code (Rough conversion for display)
    const multiplier = currencyCode === 'INR' ? 1 : (currencyCode === 'USD' ? 0.012 : 1);

    const alternatives = [
        {
            id: 'current',
            name: 'Current Deal',
            trim: 'Honda City V CVT',
            monthly: currentCarMonthly * multiplier,
            tag: 'Your Selection',
            isCurrent: true
        },
        {
            id: 1,
            name: 'Hyundai Verna',
            trim: 'SX 1.5 Turbo',
            monthly: 26800 * multiplier,
            diff: -1700 * multiplier,
            distance: 8,
            reason: 'Better resale value'
        },
        {
            id: 2,
            name: 'Maruti Ciaz',
            trim: 'Alpha AT',
            monthly: 24500 * multiplier,
            diff: -4000 * multiplier,
            distance: 12,
            reason: 'Lower maintenance'
        },
        {
            id: 3,
            name: 'Skoda Slavia',
            trim: 'Style 1.0 TSI',
            monthly: 29200 * multiplier,
            diff: +700 * multiplier,
            distance: 5,
            reason: 'Better safety rating'
        },
    ];

    const toggleExpand = () => {
        if (onToggle) {
            onToggle(!isExpanded);
        } else {
            setInternalExpanded(!internalExpanded);
        }
    };

    if (!isExpanded) {
        return (
            <div className="alt-strip-collapsed" onClick={toggleExpand}>
                <span className="alt-label">Compare Alternatives</span>
                <span className="alt-count">{alternatives.length - 1} nearby</span>
                <span className="expand-chevron">▼</span>
            </div>
        );
    }

    return (
        <div className="alt-strip-expanded">
            <div className="alt-strip-header">
                <div className="header-left">
                    <h4>Smart Alternatives</h4>
                    <span className="location-label">{getLocationLabel()}</span>
                </div>
                <button className="collapse-btn" onClick={toggleExpand}>✕</button>
            </div>

            <div className="alt-cards-scroll">
                {alternatives.map((car) => (
                    <div
                        key={car.id}
                        className={`alt - card - clean ${car.isCurrent ? 'current' : ''} `}
                    >
                        {car.tag && <span className="car-tag">{car.tag}</span>}

                        <div className="car-header">
                            <h5>{car.name}</h5>
                            <span className="car-trim">{car.trim}</span>
                        </div>

                        <div className="car-price-block">
                            <span className="price-main">{formatCurrency(car.monthly, null, currencyCode)}</span>
                            <span className="price-period">/month</span>
                        </div>

                        {!car.isCurrent && (
                            <>
                                <div className="car-diff">
                                    <span className={car.diff < 0 ? 'save' : 'extra'}>
                                        {car.diff < 0 ? 'Save ' : '+'}{formatCurrency(Math.abs(car.diff), null, currencyCode)}
                                    </span>
                                </div>
                                <div className="car-meta">
                                    <span className="distance">📍 {car.distance} km away</span>
                                    <span className="reason">{car.reason}</span>
                                </div>
                            </>
                        )}
                    </div>
                ))}
            </div>

            <div className="alt-strip-footer">
                <span className="confidence-note">Based on market data in your area</span>
            </div>
        </div>
    );
};

export default AlternativeCarsStrip;
