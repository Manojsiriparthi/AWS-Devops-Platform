import React, { useState, useEffect } from 'react';
import './Hero.css';

const Hero = () => {
  const [currentSlide, setCurrentSlide] = useState(0);
  
  const heroContent = [
    {
      id: 1,
      title: "Kubernetes Chronicles",
      subtitle: "The Ultimate DevOps Adventure",
      description: "Experience the epic journey of container orchestration in this thrilling series. Watch as microservices battle for resources while Kubernetes maintains perfect harmony across the cluster.",
      image: "https://via.placeholder.com/1920x1080/326ce5/ffffff?text=Kubernetes+Chronicles",
      rating: "98% Match",
      year: "2024",
      genre: "DevOps • Container Orchestration • Cloud Native",
      duration: "8 Episodes"
    },
    {
      id: 2,
      title: "AWS EKS: Rise of the Clusters",
      subtitle: "Managed Kubernetes Excellence",
      description: "Discover the power of Amazon EKS as it revolutionizes how we deploy and manage Kubernetes clusters. From private subnets to load balancers, witness infrastructure magic.",
      image: "https://via.placeholder.com/1920x1080/ff9900/ffffff?text=AWS+EKS+Rise",
      rating: "96% Match", 
      year: "2024",
      genre: "AWS • Infrastructure • Automation",
      duration: "Series"
    },
    {
      id: 3,
      title: "Day 4: The Application Awakens",
      subtitle: "From Code to Kubernetes",
      description: "Follow the incredible transformation of a simple React application as it becomes containerized, deployed to EKS, and exposed to the world through Application Load Balancers.",
      image: "https://via.placeholder.com/1920x1080/e50914/ffffff?text=Day+4+Application",
      rating: "94% Match",
      year: "2024", 
      genre: "React • Docker • Helm • DevOps",
      duration: "Documentary"
    }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % heroContent.length);
    }, 8000);

    return () => clearInterval(timer);
  }, [heroContent.length]);

  const currentContent = heroContent[currentSlide];

  const handlePlayClick = () => {
    alert(`🎬 Playing "${currentContent.title}" - This is a demo! In production, this would start video playback.`);
  };

  const handleInfoClick = () => {
    alert(`ℹ️ More info about "${currentContent.title}": ${currentContent.description}`);
  };

  return (
    <section className="hero">
      <div className="hero-background">
        <div 
          className="hero-image"
          style={{ backgroundImage: `url(${currentContent.image})` }}
        >
          <div className="hero-overlay"></div>
        </div>
      </div>
      
      <div className="hero-content">
        <div className="hero-info fade-in">
          <div className="hero-meta">
            <span className="hero-rating">{currentContent.rating}</span>
            <span className="hero-year">{currentContent.year}</span>
            <span className="hero-duration">{currentContent.duration}</span>
          </div>
          
          <h1 className="hero-title slide-in-left">
            {currentContent.title}
          </h1>
          
          <h2 className="hero-subtitle">
            {currentContent.subtitle}
          </h2>
          
          <p className="hero-description">
            {currentContent.description}
          </p>
          
          <div className="hero-genre">
            {currentContent.genre}
          </div>
          
          <div className="hero-actions">
            <button 
              className="btn btn-primary"
              onClick={handlePlayClick}
            >
              <span className="btn-icon">▶️</span>
              Play
            </button>
            
            <button 
              className="btn btn-secondary"
              onClick={handleInfoClick}
            >
              <span className="btn-icon">ℹ️</span>
              More Info
            </button>
            
            <button className="btn btn-tertiary">
              <span className="btn-icon">👍</span>
              Like
            </button>
            
            <button className="btn btn-tertiary">
              <span className="btn-icon">➕</span>
              My List
            </button>
          </div>
        </div>
      </div>
      
      {/* Slide Indicators */}
      <div className="hero-indicators">
        {heroContent.map((_, index) => (
          <button
            key={index}
            className={`indicator ${index === currentSlide ? 'active' : ''}`}
            onClick={() => setCurrentSlide(index)}
            aria-label={`Go to slide ${index + 1}`}
          />
        ))}
      </div>
      
      {/* Kubernetes Infrastructure Info */}
      <div className="hero-tech-info">
        <div className="tech-badge">
          <span className="tech-icon">☸️</span>
          <div className="tech-details">
            <div className="tech-title">Powered by Kubernetes</div>
            <div className="tech-subtitle">Running on AWS EKS • Private Subnets • Auto-scaling</div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;