import React from 'react';
import './Intelligence.css';

const ScenarioFAB = ({ onClick }) => {
    return (
        <button className="scenario-fab glass-fab" onClick={onClick}>
            <span className="fab-icon">⚡</span>
            <span className="fab-label">Simulate</span>
        </button>
    );
};

export default ScenarioFAB;
