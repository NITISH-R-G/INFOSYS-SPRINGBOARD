import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { listContracts, deleteContract } from '../services/api'
import './Dashboard.css'

export default function Dashboard() {
    const [contracts, setContracts] = useState([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState('')

    useEffect(() => {
        fetchContracts()
    }, [])

    const fetchContracts = async () => {
        try {
            const data = await listContracts()
            setContracts(data)
        } catch (err) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }

    const handleDelete = async (id) => {
        if (!window.confirm('Delete this contract?')) return

        try {
            await deleteContract(id)
            setContracts(contracts.filter(c => c.id !== id))
        } catch (err) {
            alert('Failed to delete: ' + err.message)
        }
    }

    const getScoreClass = (score) => {
        if (score >= 80) return 'excellent'
        if (score >= 60) return 'good'
        if (score >= 40) return 'fair'
        return 'poor'
    }

    const getStatusBadge = (status) => {
        switch (status) {
            case 'analyzed':
                return <span className="badge badge-success">Analyzed</span>
            case 'processing':
                return <span className="badge badge-info">Processing</span>
            case 'uploaded':
                return <span className="badge badge-warning">Pending</span>
            default:
                return <span className="badge">{status}</span>
        }
    }

    return (
        <div className="page">
            <div className="container">
                {/* Header */}
                <div className="dashboard-header">
                    <div>
                        <h1>Welcome!</h1>
                        <p className="text-muted">Here's an overview of your contracts</p>
                    </div>
                    <Link to="/upload" className="btn btn-primary">
                        <i className="ph ph-plus"></i>
                        Upload Contract
                    </Link>
                </div>

                {/* Stats Cards */}
                <div className="stats-grid">
                    <div className="stat-card glass-panel">
                        <div className="stat-icon blue">
                            <i className="ph-fill ph-files"></i>
                        </div>
                        <div className="stat-info">
                            <span className="stat-value">{contracts.length}</span>
                            <span className="stat-label">Total Contracts</span>
                        </div>
                    </div>

                    <div className="stat-card glass-panel">
                        <div className="stat-icon green">
                            <i className="ph-fill ph-check-circle"></i>
                        </div>
                        <div className="stat-info">
                            <span className="stat-value">
                                {contracts.filter(c => c.status === 'analyzed').length}
                            </span>
                            <span className="stat-label">Analyzed</span>
                        </div>
                    </div>

                    <div className="stat-card glass-panel">
                        <div className="stat-icon orange">
                            <i className="ph-fill ph-warning"></i>
                        </div>
                        <div className="stat-info">
                            <span className="stat-value">
                                {contracts.reduce((sum, c) => sum + (c.red_flags?.length || 0), 0)}
                            </span>
                            <span className="stat-label">Red Flags Found</span>
                        </div>
                    </div>

                    <div className="stat-card glass-panel">
                        <div className="stat-icon purple">
                            <i className="ph-fill ph-chart-line-up"></i>
                        </div>
                        <div className="stat-info">
                            <span className="stat-value">
                                {contracts.filter(c => c.fairness_score).length > 0
                                    ? Math.round(
                                        contracts
                                            .filter(c => c.fairness_score)
                                            .reduce((sum, c) => sum + c.fairness_score, 0) /
                                        contracts.filter(c => c.fairness_score).length
                                    )
                                    : '--'}
                            </span>
                            <span className="stat-label">Avg. Fairness</span>
                        </div>
                    </div>
                </div>

                {/* Contracts List */}
                <div className="section-header">
                    <h2>Your Contracts</h2>
                </div>

                {loading ? (
                    <div className="loading-box glass-panel">
                        <div className="spinner spinner-dark"></div>
                        <span>Loading contracts...</span>
                    </div>
                ) : error ? (
                    <div className="error-box glass-panel">
                        <i className="ph-fill ph-warning-circle"></i>
                        {error}
                    </div>
                ) : contracts.length === 0 ? (
                    <div className="empty-state glass-panel">
                        <i className="ph-light ph-file-arrow-up"></i>
                        <h3>No contracts yet</h3>
                        <p>Upload your first car lease or loan contract to get started</p>
                        <Link to="/upload" className="btn btn-primary">
                            <i className="ph ph-upload"></i>
                            Upload Contract
                        </Link>
                    </div>
                ) : (
                    <div className="contracts-list">
                        {contracts.map(contract => (
                            <div key={contract.id} className="contract-card glass-panel">
                                <div className="contract-icon">
                                    <i className="ph-fill ph-file-text"></i>
                                </div>

                                <div className="contract-info">
                                    <h3>{contract.filename}</h3>
                                    <div className="contract-meta">
                                        {getStatusBadge(contract.status)}
                                        <span className="contract-date">
                                            {new Date(contract.created_at).toLocaleDateString()}
                                        </span>
                                        {contract.contract_type && (
                                            <span className="contract-type">
                                                {contract.contract_type.toUpperCase()}
                                            </span>
                                        )}
                                    </div>
                                </div>

                                {contract.fairness_score !== null && (
                                    <div className="contract-score">
                                        <div className={`score-circle ${getScoreClass(contract.fairness_score)}`}>
                                            {contract.fairness_score}
                                        </div>
                                        <span className="score-label">Fairness</span>
                                    </div>
                                )}

                                <div className="contract-actions">
                                    <Link
                                        to={`/contract/${contract.id}`}
                                        className="btn btn-secondary"
                                    >
                                        View Details
                                    </Link>
                                    <button
                                        className="btn btn-icon btn-secondary"
                                        onClick={() => handleDelete(contract.id)}
                                    >
                                        <i className="ph ph-trash"></i>
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    )
}
