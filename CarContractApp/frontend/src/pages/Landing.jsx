import { Link } from 'react-router-dom'
import './Landing.css'

export default function Landing() {
    return (
        <div className="landing-page">
            {/* Hero Section */}
            <section className="hero">
                <div className="hero-content">
                    <div className="hero-badge">
                        <i className="ph-fill ph-sparkle"></i>
                        AI-Powered Contract Analysis
                    </div>
                    <h1 className="hero-title">
                        Understand Your Car Contract<br />
                        <span className="gradient-text">Before You Sign</span>
                    </h1>
                    <p className="hero-subtitle">
                        Get AI-powered insights into your car lease or loan contract.
                        Identify hidden fees, understand the fine print, and negotiate better terms.
                    </p>
                    <div className="hero-buttons">
                        <Link to="/dashboard" className="btn btn-primary btn-lg">
                            Get Started
                            <i className="ph ph-arrow-right"></i>
                        </Link>
                        <Link to="/upload" className="btn btn-secondary btn-lg">
                            Upload Contract
                        </Link>
                    </div>
                </div>

                <div className="hero-visual">
                    <div className="hero-card glass-panel">
                        <div className="hero-card-header">
                            <i className="ph-fill ph-file-text"></i>
                            Contract Analysis
                        </div>
                        <div className="hero-card-body">
                            <div className="mini-meter">
                                <span>Fairness Score</span>
                                <div className="mini-bar">
                                    <div className="mini-fill" style={{ width: '78%' }}></div>
                                </div>
                                <span className="mini-value">78/100</span>
                            </div>
                            <div className="mini-flags">
                                <div className="mini-flag">
                                    <i className="ph-fill ph-warning"></i>
                                    High documentation fee detected
                                </div>
                                <div className="mini-flag">
                                    <i className="ph-fill ph-warning"></i>
                                    Below-market mileage allowance
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section className="features">
                <div className="container">
                    <h2 className="section-title">Everything You Need to Make Smart Decisions</h2>

                    <div className="features-grid">
                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-scan"></i>
                            </div>
                            <h3>Smart Contract Scanning</h3>
                            <p>Upload your contract and our AI extracts all the critical terms automatically.</p>
                        </div>

                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-chart-line-up"></i>
                            </div>
                            <h3>Fairness Score</h3>
                            <p>Get an instant 0-100 score showing how fair your contract terms are.</p>
                        </div>

                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-warning-octagon"></i>
                            </div>
                            <h3>Red Flag Detection</h3>
                            <p>Identify hidden fees, excessive penalties, and unfavorable clauses.</p>
                        </div>

                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-car"></i>
                            </div>
                            <h3>VIN Lookup</h3>
                            <p>Check vehicle history, recalls, and specifications using the VIN.</p>
                        </div>

                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-currency-dollar"></i>
                            </div>
                            <h3>Price Estimation</h3>
                            <p>Get fair market value estimates to ensure you're getting a good deal.</p>
                        </div>

                        <div className="feature-card glass-panel">
                            <div className="feature-icon">
                                <i className="ph-fill ph-chat-circle-text"></i>
                            </div>
                            <h3>Negotiation AI</h3>
                            <p>Get personalized advice and email templates to negotiate better terms.</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="cta">
                <div className="container">
                    <div className="cta-box glass-panel">
                        <h2>Ready to Review Your Contract?</h2>
                        <p>Join thousands of smart car buyers who use ContractAI</p>
                        <Link to="/upload" className="btn btn-primary btn-lg">
                            Start Analysis
                            <i className="ph ph-arrow-right"></i>
                        </Link>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className="footer">
                <div className="container">
                    <div className="footer-brand">
                        <i className="ph-fill ph-car-profile"></i>
                        <span>ContractAI</span>
                    </div>
                    <p className="footer-text">
                        © 2026 Car Contract Review AI. Built for Infosys Springboard Internship.
                    </p>
                </div>
            </footer>
        </div>
    )
}
