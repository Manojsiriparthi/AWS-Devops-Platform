import React from 'react';
import './Footer.css';

const Footer = ({ systemInfo }) => {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="footer">
      {/* Kubernetes Infrastructure Section */}
      <section className="infrastructure-info">
        <div className="container">
          <h3 className="section-title">
            ☸️ Kubernetes Infrastructure Details
          </h3>
          
          <div className="info-grid">
            <div className="info-card">
              <div className="info-icon">🏗️</div>
              <div className="info-content">
                <h4>Deployment Architecture</h4>
                <p>React App → Docker Container → ECR → EKS → Private Subnets → ALB → Internet</p>
              </div>
            </div>
            
            <div className="info-card">
              <div className="info-icon">📦</div>
              <div className="info-content">
                <h4>Container Details</h4>
                <p>Pod: {systemInfo.podName}</p>
                <p>Namespace: {systemInfo.namespace}</p>
                <p>Node: {systemInfo.nodeName}</p>
              </div>
            </div>
            
            <div className="info-card">
              <div className="info-icon">🌐</div>
              <div className="info-content">
                <h4>Network Configuration</h4>
                <p>Pod IP: {systemInfo.podIP}</p>
                <p>Environment: {systemInfo.environment}</p>
                <p>Load Balancer: Application Load Balancer</p>
              </div>
            </div>
            
            <div className="info-card">
              <div className="info-icon">🚀</div>
              <div className="info-content">
                <h4>Technology Stack</h4>
                <p>Frontend: React 18 + Modern CSS</p>
                <p>Container: Docker Multi-stage Build</p>
                <p>Orchestration: Kubernetes + Helm</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* AWS Architecture Section */}
      <section className="aws-architecture">
        <div className="container">
          <h3 className="section-title">
            ☁️ AWS Infrastructure Overview
          </h3>
          
          <div className="architecture-flow">
            <div className="flow-item">
              <div className="flow-icon">🌐</div>
              <div className="flow-label">Internet</div>
            </div>
            <div className="flow-arrow">→</div>
            
            <div className="flow-item">
              <div className="flow-icon">⚖️</div>
              <div className="flow-label">Application<br/>Load Balancer</div>
            </div>
            <div className="flow-arrow">→</div>
            
            <div className="flow-item">
              <div className="flow-icon">🔒</div>
              <div className="flow-label">Private<br/>Subnets</div>
            </div>
            <div className="flow-arrow">→</div>
            
            <div className="flow-item">
              <div className="flow-icon">☸️</div>
              <div className="flow-label">EKS<br/>Cluster</div>
            </div>
            <div className="flow-arrow">→</div>
            
            <div className="flow-item active">
              <div className="flow-icon">📦</div>
              <div className="flow-label">StreamFlix<br/>Pod</div>
            </div>
          </div>
        </div>
      </section>

      {/* Links Section */}
      <section className="footer-links">
        <div className="container">
          <div className="links-grid">
            <div className="link-column">
              <h4>StreamFlix</h4>
              <ul>
                <li><a href="#about">About Us</a></li>
                <li><a href="#careers">Careers</a></li>
                <li><a href="#press">Press</a></li>
                <li><a href="#blog">Engineering Blog</a></li>
              </ul>
            </div>
            
            <div className="link-column">
              <h4>Support</h4>
              <ul>
                <li><a href="#help">Help Center</a></li>
                <li><a href="#contact">Contact Us</a></li>
                <li><a href="#status">System Status</a></li>
                <li><a href="#api">API Documentation</a></li>
              </ul>
            </div>
            
            <div className="link-column">
              <h4>DevOps</h4>
              <ul>
                <li><a href="#kubernetes">Kubernetes Guide</a></li>
                <li><a href="#docker">Docker Best Practices</a></li>
                <li><a href="#aws">AWS Architecture</a></li>
                <li><a href="#cicd">CI/CD Pipeline</a></li>
              </ul>
            </div>
            
            <div className="link-column">
              <h4>Legal</h4>
              <ul>
                <li><a href="#privacy">Privacy Policy</a></li>
                <li><a href="#terms">Terms of Service</a></li>
                <li><a href="#cookies">Cookie Preferences</a></li>
                <li><a href="#accessibility">Accessibility</a></li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Bottom Bar */}
      <section className="footer-bottom">
        <div className="container">
          <div className="bottom-content">
            <div className="copyright">
              <p>© {currentYear} StreamFlix - Day 4 Kubernetes Demo. Built with ❤️ for learning DevOps.</p>
              <p className="tech-note">
                Powered by React, Docker, Kubernetes, AWS EKS, and Terraform
              </p>
            </div>
            
            <div className="social-links">
              <a href="#github" className="social-link" title="GitHub">
                <span>🐙</span>
              </a>
              <a href="#docker" className="social-link" title="Docker Hub">
                <span>🐳</span>
              </a>
              <a href="#kubernetes" className="social-link" title="Kubernetes">
                <span>☸️</span>
              </a>
              <a href="#aws" className="social-link" title="AWS">
                <span>☁️</span>
              </a>
            </div>
          </div>
          
          <div className="build-info">
            <div className="build-details">
              <span>🏗️ Build Info:</span>
              <span>Environment: {systemInfo.environment}</span>
              <span>•</span>
              <span>Built: {new Date().toLocaleDateString()}</span>
              <span>•</span>
              <span>Version: 1.0.0</span>
            </div>
          </div>
        </div>
      </section>
    </footer>
  );
};

export default Footer;