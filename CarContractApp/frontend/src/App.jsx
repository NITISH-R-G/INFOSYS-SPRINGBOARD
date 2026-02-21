import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { useState, useEffect } from 'react'

// Pages
import Landing from './pages/Landing'
import Dashboard from './pages/Dashboard'
import Upload from './pages/Upload'
import ContractDetail from './pages/ContractDetail'
import VINLookup from './pages/VINLookup'
import Negotiate from './pages/Negotiate'

// Components
import Navbar from './components/Navbar'

import './styles/index.css'

const Layout = ({ children, darkMode, setDarkMode }) => {
    return (
        <div className="app">
            <Navbar darkMode={darkMode} setDarkMode={setDarkMode} />
            <main className="main-content">
                {children}
            </main>
        </div>
    )
}

function App() {
    const [darkMode, setDarkMode] = useState(() => {
        return localStorage.getItem('theme') === 'dark'
    })

    useEffect(() => {
        if (darkMode) {
            document.body.classList.add('dark-mode')
            localStorage.setItem('theme', 'dark')
        } else {
            document.body.classList.remove('dark-mode')
            localStorage.setItem('theme', 'light')
        }
    }, [darkMode])

    return (
        <Router>
            <Routes>
                {/* Standard Layout Routes */}
                <Route path="/" element={<Layout darkMode={darkMode} setDarkMode={setDarkMode}><Landing /></Layout>} />
                <Route path="/dashboard" element={<Layout darkMode={darkMode} setDarkMode={setDarkMode}><Dashboard /></Layout>} />
                <Route path="/upload" element={<Layout darkMode={darkMode} setDarkMode={setDarkMode}><Upload /></Layout>} />
                <Route path="/vin-lookup" element={<Layout darkMode={darkMode} setDarkMode={setDarkMode}><VINLookup /></Layout>} />
                <Route path="/negotiate" element={<Layout darkMode={darkMode} setDarkMode={setDarkMode}><Negotiate /></Layout>} />

                {/* Immersive Routes (No Navbar/Padding) */}
                <Route path="/contract/:id" element={<ContractDetail />} />
            </Routes>
        </Router>
    )
}

export default App
