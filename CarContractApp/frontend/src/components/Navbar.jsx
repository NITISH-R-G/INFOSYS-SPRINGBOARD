import { Link } from 'react-router-dom'
import './Navbar.css'

export default function Navbar({ darkMode, setDarkMode }) {
    return (
        <nav className="navbar glass-panel-static">
            <div className="navbar-container">
                <Link to="/dashboard" className="navbar-brand">
                    <i className="ph-fill ph-car-profile"></i>
                    <span>ContractAI</span>
                </Link>

                <div className="navbar-links">
                    <Link to="/dashboard" className="nav-link">
                        <i className="ph ph-house"></i>
                        Dashboard
                    </Link>
                    <Link to="/upload" className="nav-link">
                        <i className="ph ph-upload"></i>
                        Upload
                    </Link>
                    <Link to="/vin-lookup" className="nav-link">
                        <i className="ph ph-magnifying-glass"></i>
                        VIN Lookup
                    </Link>
                    <Link to="/negotiate" className="nav-link">
                        <i className="ph ph-chat-circle-text"></i>
                        Negotiate
                    </Link>
                </div>

                <div className="navbar-right">
                    <label className="theme-switch">
                        <input
                            type="checkbox"
                            checked={darkMode}
                            onChange={(e) => setDarkMode(e.target.checked)}
                        />
                        <span className="slider">
                            <i className="ph-fill ph-sun icon-sun"></i>
                            <i className="ph-fill ph-moon icon-moon"></i>
                        </span>
                    </label>
                </div>
            </div>
        </nav>
    )
}
