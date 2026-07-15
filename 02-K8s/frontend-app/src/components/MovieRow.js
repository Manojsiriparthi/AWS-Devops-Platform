import React, { useRef, useState } from 'react';
import './MovieRow.css';

const MovieRow = ({ title, movies, delay = 0 }) => {
  const rowRef = useRef(null);
  const [scrollPosition, setScrollPosition] = useState(0);
  const [selectedMovie, setSelectedMovie] = useState(null);

  const scroll = (direction) => {
    const container = rowRef.current;
    if (container) {
      const scrollAmount = 300;
      const newScrollPosition = direction === 'left' 
        ? Math.max(0, scrollPosition - scrollAmount)
        : Math.min(container.scrollWidth - container.clientWidth, scrollPosition + scrollAmount);
      
      container.scrollTo({
        left: newScrollPosition,
        behavior: 'smooth'
      });
      setScrollPosition(newScrollPosition);
    }
  };

  const handleMovieClick = (movie) => {
    setSelectedMovie(movie);
    // In a real app, this would navigate to the movie detail page or open a modal
    alert(`🎬 You selected: "${movie.title}"\n\n${movie.description}\n\nRating: ${movie.rating}\nYear: ${movie.year}`);
  };

  const handleScroll = (e) => {
    setScrollPosition(e.target.scrollLeft);
  };

  return (
    <div className="movie-row" style={{ animationDelay: `${delay}s` }}>
      <h2 className="row-title">{title}</h2>
      
      <div className="row-container">
        <button 
          className="scroll-btn scroll-btn-left"
          onClick={() => scroll('left')}
          style={{ display: scrollPosition > 0 ? 'flex' : 'none' }}
          aria-label="Scroll left"
        >
          ‹
        </button>
        
        <div 
          className="movies-container"
          ref={rowRef}
          onScroll={handleScroll}
        >
          {movies.map((movie, index) => (
            <div
              key={movie.id}
              className="movie-card"
              onClick={() => handleMovieClick(movie)}
              style={{ animationDelay: `${delay + (index * 0.1)}s` }}
            >
              <div className="movie-image">
                <img 
                  src={movie.image} 
                  alt={movie.title}
                  loading="lazy"
                />
                <div className="movie-overlay">
                  <div className="movie-actions">
                    <button className="action-btn play-btn">
                      <span>▶️</span>
                    </button>
                    <button className="action-btn like-btn">
                      <span>👍</span>
                    </button>
                    <button className="action-btn add-btn">
                      <span>➕</span>
                    </button>
                    <button className="action-btn info-btn">
                      <span>ℹ️</span>
                    </button>
                  </div>
                </div>
              </div>
              
              <div className="movie-info">
                <div className="movie-meta">
                  <span className="movie-rating">{movie.rating}</span>
                  <span className="movie-year">{movie.year}</span>
                </div>
                <h3 className="movie-title">{movie.title}</h3>
                <p className="movie-description">{movie.description}</p>
              </div>
            </div>
          ))}
          
          {/* Loading placeholder for infinite scroll effect */}
          <div className="movie-card loading-card">
            <div className="movie-image loading-placeholder">
              <div className="loading-text">Loading more...</div>
            </div>
            <div className="movie-info">
              <div className="movie-title">Coming Soon</div>
            </div>
          </div>
        </div>
        
        <button 
          className="scroll-btn scroll-btn-right"
          onClick={() => scroll('right')}
          aria-label="Scroll right"
        >
          ›
        </button>
      </div>
    </div>
  );
};

export default MovieRow;