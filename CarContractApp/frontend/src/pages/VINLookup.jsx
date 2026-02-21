import { useState } from 'react'
import { lookupVIN, estimatePrice } from '../services/api'
import './VINLookup.css'

export default function VINLookup() {
    const [vin, setVin] = useState('')
    const [loading, setLoading] = useState(false)
    const [vehicleData, setVehicleData] = useState(null)
    const [priceData, setPriceData] = useState(null)
    const [error, setError] = useState('')

    const handleLookup = async (e) => {
        e.preventDefault()
        if (!vin || vin.length !== 17) {
            setError('VIN must be exactly 17 characters')
            return
        }

        setLoading(true)
        setError('')
        setVehicleData(null)
        setPriceData(null)

        try {
            const data = await lookupVIN(vin)
            setVehicleData(data)

            // Also get price estimate
            if (data.make && data.model && data.year) {
                try {
                    const price = await estimatePrice({
                        make: data.make,
                        model: data.model,
                        year: data.year
                    })
                    setPriceData(price)
                } catch {
                    // Price estimation is optional
                }
            }
        } catch (err) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="page">
            <div className="container">
                <div className="vin-header">
                    <h1>VIN Lookup</h1>
                    <p className="text-muted">Look up vehicle details and history using the VIN</p>
                </div>

                <div className="vin-content">
                    {/* Search Form */}
                    <div className="vin-search glass-panel-static">
                        <form onSubmit={handleLookup}>
                            <div className="vin-input-group">
                                <div className="vin-input-wrapper">
                                    <i className="ph ph-barcode"></i>
                                    <input
                                        type="text"
                                        className="vin-input"
                                        value={vin}
                                        onChange={(e) => setVin(e.target.value.toUpperCase())}
                                        placeholder="Enter 17-character VIN"
                                        maxLength={17}
                                    />
                                    <span className="vin-count">{vin.length}/17</span>
                                </div>
                                <button
                                    type="submit"
                                    className="btn btn-primary btn-lg"
                                    disabled={loading || vin.length !== 17}
                                >
                                    {loading ? (
                                        <>
                                            <div className="spinner"></div>
                                            Looking up...
                                        </>
                                    ) : (
                                        <>
                                            <i className="ph ph-magnifying-glass"></i>
                                            Look Up
                                        </>
                                    )}
                                </button>
                            </div>
                        </form>

                        {error && (
                            <div className="vin-error">
                                <i className="ph-fill ph-warning-circle"></i>
                                {error}
                            </div>
                        )}
                    </div>

                    {/* Results */}
                    {vehicleData && (
                        <div className="vin-results animate-fade-in">
                            {/* Vehicle Info */}
                            <div className="vehicle-card glass-panel-static">
                                <div className="vehicle-header">
                                    <div className="vehicle-icon">
                                        <i className="ph-fill ph-car"></i>
                                    </div>
                                    <div className="vehicle-title">
                                        <h2>{vehicleData.year} {vehicleData.make} {vehicleData.model}</h2>
                                        <span className="vin-display">{vehicleData.vin}</span>
                                    </div>
                                </div>

                                <div className="vehicle-specs">
                                    <div className="spec-item">
                                        <span className="spec-label">Trim</span>
                                        <span className="spec-value">{vehicleData.trim || '--'}</span>
                                    </div>
                                    <div className="spec-item">
                                        <span className="spec-label">Body Type</span>
                                        <span className="spec-value">{vehicleData.body_type || '--'}</span>
                                    </div>
                                    <div className="spec-item">
                                        <span className="spec-label">Engine</span>
                                        <span className="spec-value">{vehicleData.engine || '--'}</span>
                                    </div>
                                    <div className="spec-item">
                                        <span className="spec-label">Transmission</span>
                                        <span className="spec-value">{vehicleData.transmission || '--'}</span>
                                    </div>
                                    <div className="spec-item">
                                        <span className="spec-label">Drivetrain</span>
                                        <span className="spec-value">{vehicleData.drivetrain || '--'}</span>
                                    </div>
                                    <div className="spec-item">
                                        <span className="spec-label">Fuel Type</span>
                                        <span className="spec-value">{vehicleData.fuel_type || '--'}</span>
                                    </div>
                                </div>
                            </div>

                            {/* Price Estimate */}
                            {priceData && (
                                <div className="price-card glass-panel-static">
                                    <h3>
                                        <i className="ph-fill ph-currency-dollar"></i>
                                        Estimated Value
                                    </h3>
                                    <div className="price-range">
                                        <div className="price-low">
                                            <span className="price-label">Low</span>
                                            <span className="price-value">${priceData.estimated_value_low?.toLocaleString()}</span>
                                        </div>
                                        <div className="price-avg">
                                            <span className="price-label">Average</span>
                                            <span className="price-value">${priceData.estimated_value_avg?.toLocaleString()}</span>
                                        </div>
                                        <div className="price-high">
                                            <span className="price-label">High</span>
                                            <span className="price-value">${priceData.estimated_value_high?.toLocaleString()}</span>
                                        </div>
                                    </div>
                                    <div className="price-confidence">
                                        Confidence: <strong>{priceData.confidence}</strong>
                                    </div>
                                    {priceData.notes && (
                                        <p className="price-notes">{priceData.notes}</p>
                                    )}
                                </div>
                            )}

                            {/* Recalls */}
                            {vehicleData.recalls && vehicleData.recalls.length > 0 && (
                                <div className="recalls-card glass-panel-static">
                                    <h3>
                                        <i className="ph-fill ph-warning-octagon"></i>
                                        Recalls ({vehicleData.recalls.length})
                                    </h3>
                                    <div className="recalls-list">
                                        {vehicleData.recalls.map((recall, index) => (
                                            <div key={index} className="recall-item">
                                                <div className="recall-header">
                                                    <span className="recall-campaign">{recall.campaign_number}</span>
                                                    <span className="recall-date">{recall.report_date}</span>
                                                </div>
                                                <div className="recall-component">{recall.component}</div>
                                                <p className="recall-summary">{recall.summary}</p>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {vehicleData.recalls && vehicleData.recalls.length === 0 && (
                                <div className="no-recalls glass-panel-static">
                                    <i className="ph-fill ph-check-circle"></i>
                                    <span>No recalls found for this vehicle</span>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Info */}
                    {!vehicleData && !loading && (
                        <div className="vin-info glass-panel-static">
                            <h3>Where to Find the VIN?</h3>
                            <ul>
                                <li><i className="ph ph-check"></i> Driver's side dashboard (visible through windshield)</li>
                                <li><i className="ph ph-check"></i> Driver's side door jamb sticker</li>
                                <li><i className="ph ph-check"></i> Vehicle registration or title</li>
                                <li><i className="ph ph-check"></i> Insurance documents</li>
                            </ul>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}
