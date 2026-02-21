import { useState, useEffect, useRef } from 'react'
import { useSearchParams } from 'react-router-dom'
import { sendNegotiationChat, getNegotiationTips, getContract } from '../services/api'
import './Negotiate.css'

export default function Negotiate() {
    const [searchParams] = useSearchParams()
    const contractId = searchParams.get('contract')

    const [messages, setMessages] = useState([])
    const [input, setInput] = useState('')
    const [sending, setSending] = useState(false)
    const [sessionId, setSessionId] = useState(null)
    const [tips, setTips] = useState(null)
    const [contract, setContract] = useState(null)
    const messagesEndRef = useRef(null)

    useEffect(() => {
        fetchTips()
        if (contractId) fetchContract()
    }, [contractId])

    useEffect(() => { scrollToBottom() }, [messages])

    const fetchTips = async () => {
        try { setTips(await getNegotiationTips()) } catch { }
    }

    const fetchContract = async () => {
        try {
            const data = await getContract(contractId)
            setContract(data)
            setMessages([{
                role: 'assistant',
                content: `I see you're reviewing a contract with a fairness score of ${data.fairness_score}/100. How can I help?`
            }])
        } catch { }
    }

    const scrollToBottom = () => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })

    const handleSend = async (e) => {
        e.preventDefault()
        if (!input.trim() || sending) return
        const userMessage = input.trim()
        setInput('')
        setMessages(prev => [...prev, { role: 'user', content: userMessage }])
        setSending(true)
        try {
            const resp = await sendNegotiationChat(userMessage, contractId ? parseInt(contractId) : null, sessionId)
            setSessionId(resp.session_id)
            setMessages(prev => [...prev, { role: 'assistant', content: resp.response }])
        } catch {
            setMessages(prev => [...prev, { role: 'assistant', content: 'Error. Please try again.', isError: true }])
        } finally { setSending(false) }
    }

    const quickQs = ["What's a good APR?", "How to negotiate monthly payment?", "What fees to remove?"]

    return (
        <div className="page">
            <div className="container">
                <div className="negotiate-layout">
                    <div className="chat-section glass-panel-static">
                        <div className="chat-header">
                            <i className="ph-fill ph-chat-circle-text"></i>
                            <h2>Negotiation Assistant</h2>
                        </div>
                        <div className="chat-messages">
                            {messages.length === 0 && (
                                <div className="chat-welcome">
                                    <h3>How can I help?</h3>
                                    <div className="quick-questions">
                                        {quickQs.map((q, i) => <button key={i} onClick={() => setInput(q)}>{q}</button>)}
                                    </div>
                                </div>
                            )}
                            {messages.map((msg, i) => <div key={i} className={`chat-message ${msg.role}`}>{msg.content}</div>)}
                            {sending && <div className="chat-message assistant"><span className="typing">...</span></div>}
                            <div ref={messagesEndRef} />
                        </div>
                        <form className="chat-input-form" onSubmit={handleSend}>
                            <input value={input} onChange={(e) => setInput(e.target.value)} placeholder="Type..." disabled={sending} />
                            <button type="submit" className="btn btn-primary"><i className="ph ph-paper-plane-right"></i></button>
                        </form>
                    </div>
                    <div className="tips-section">
                        {tips && <div className="tips-card glass-panel-static"><h3>Tips</h3><ul>{tips.general?.slice(0, 4).map((t, i) => <li key={i}>{t}</li>)}</ul></div>}
                    </div>
                </div>
            </div>
        </div>
    )
}
