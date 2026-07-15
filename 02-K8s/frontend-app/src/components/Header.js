import React, { useState, useEffect } from 'react';
import './Header.css';

const Header = ({ systemInfo }) => {
  const [scrolled, setScrolled] = useState(false);
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const handleScroll = () => {
      const isScrolled = window.scrollY > 100;
      setScrolled(isScrolled);
    };

    const timeInterval = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    window.addEventListener('scroll', handleScroll);
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
      clearInterval(timeInterval);
    };
  }, []);

  return (
    <header className={`header ${scrolled ? 'scrolled' : ''}`}>
      <div className="header-content">
        <div className="header-left">
          <div className="logo">
            <span className="logo-icon">🎬</span>
            <span className="logo-text">StreamFlix</span>
          </div>
          <nav className="nav-menu">
            <a href="#home" className="nav-item active">Home</a>
            <a href="#movies" className="nav-item">Movies</a>
            <a href="#series" className="nav-item">TV Shows</a>
            <a href="#kubernetes" className="nav-item">Kubernetes</a>
            <a href="#devops" className="nav-item">DevOps</a>
          </nav>
        </div>
        
        <div className="header-right">
          <div className="system-status">
            <span className="status-indicator online"></span>
            <span className="status-text">Live from EKS</span>
          </div>
          
          <div className="time-display">
            {currentTime.toLocaleTimeString()}
          </div>
          
          <div className="user-menu">
            <div className="user-avatar">
              <span>👤</span>
            </div>
            <div className="user-dropdown">
              <div className="dropdown-item">
                <strong>Pod:</strong> {systemInfo.podName}
              </div>
              <div className="dropdown-item">
                <strong>Environment:</strong> {systemInfo.environment}
              </div>
              <div className="dropdown-item">
                <strong>Namespace:</strong> {systemInfo.namespace}
              </div>
              <hr />
              <div className="dropdown-item">Account Settings</div>
              <div className="dropdown-item">Sign out of StreamFlix</div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Kubernetes Info Banner */}
      <div className="k8s-info-banner">
        <div className="k8s-info">
          <span className="k8s-badge">☸️ Kubernetes</span>
          <span className="k8s-detail">
            Pod: {systemInfo.podName} | Node: {systemInfo.nodeName.split('.')[0]} | IP: {systemInfo.podIP}
          </span>
        </div>
        <div className="deployment-info">
          <span className="deployment-badge">🚀 Day 4 Demo</span>
          <span className="deployment-detail">
            EKS Cluster → Private Subnets → Application Load Balancer → Internet
          </span>
        </div>
      </div>
    </header>
  );
};

export default Header;