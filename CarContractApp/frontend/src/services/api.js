/**
 * API Service - Centralized API calls
 */

const API_BASE = 'http://127.0.0.1:8000'

function getHeaders() {
    return {
        'Content-Type': 'application/json'
    }
}

// ==================== Contracts ====================

export async function uploadContract(file) {
    const formData = new FormData()
    formData.append('file', file)

    const res = await fetch(`${API_BASE}/contracts/upload`, {
        method: 'POST',
        body: formData
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Upload failed')
    }

    return await res.json()
}

export async function analyzeContract(contractId) {
    const res = await fetch(`${API_BASE}/contracts/${contractId}/analyze`, {
        method: 'POST',
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Analysis failed')
    }

    return await res.json()
}

export async function getContract(contractId) {
    const res = await fetch(`${API_BASE}/contracts/${contractId}`, {
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Failed to fetch contract')
    }

    return await res.json()
}

export async function listContracts() {
    const res = await fetch(`${API_BASE}/contracts/`, {
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Failed to fetch contracts')
    }

    return await res.json()
}

export async function deleteContract(contractId) {
    const res = await fetch(`${API_BASE}/contracts/${contractId}`, {
        method: 'DELETE',
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Delete failed')
    }

    return await res.json()
}

// ==================== Vehicles ====================

export async function lookupVIN(vin) {
    const res = await fetch(`${API_BASE}/vehicles/vin/${vin}`, {
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'VIN lookup failed')
    }

    return await res.json()
}

export async function estimatePrice(data) {
    const res = await fetch(`${API_BASE}/vehicles/price`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(data)
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Price estimation failed')
    }

    return await res.json()
}

// ==================== Negotiations ====================

export async function sendNegotiationChat(message, contractId = null, sessionId = null) {
    const res = await fetch(`${API_BASE}/negotiate/chat`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
            message,
            contract_id: contractId,
            session_id: sessionId
        })
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Chat failed')
    }

    return await res.json()
}

export async function generateNegotiationEmail(contractId, emailType, specificPoints = [], tone = 'professional') {
    const res = await fetch(`${API_BASE}/negotiate/generate-email`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
            contract_id: contractId,
            email_type: emailType,
            specific_points: specificPoints,
            tone
        })
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Email generation failed')
    }

    return await res.json()
}

export async function getNegotiationTips(contractType = null) {
    const url = contractType
        ? `${API_BASE}/negotiate/tips?contract_type=${contractType}`
        : `${API_BASE}/negotiate/tips`

    const res = await fetch(url, {
        headers: getHeaders()
    })

    if (!res.ok) {
        const error = await res.json()
        throw new Error(error.detail || 'Failed to fetch tips')
    }

    return await res.json()
}

const api = {
    uploadContract,
    analyzeContract,
    getContract,
    listContracts,
    deleteContract,
    lookupVIN,
    estimatePrice,
    sendNegotiationChat,
    generateNegotiationEmail,
    getNegotiationTips
};

export default api;
