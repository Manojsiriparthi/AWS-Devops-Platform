import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Hero from './components/Hero';
import MovieRow from './components/MovieRow';
import Footer from './components/Footer';
import './App.css';

// Mock movie data - in real app this would come from an API
const movieCategories = [
  {
    title: "Trending Now",
    movies: [
      { id: 1, title: "Kubernetes Chronicles", image: "https://via.placeholder.com/300x450/e50914/ffffff?text=K8s+Chronicles", rating: "98% Match", year: "2024", description: "Epic tale of container orchestration" },
      { id: 2, title: "Docker Adventures", image: "https://via.placeholder.com/300x450/0db7ed/ffffff?text=Docker+Adventures", rating: "95% Match", year: "2024", description: "Containerization journey" },
      { id: 3, title: "DevOps Heroes", image: "https://via.placeholder.com/300x450/326ce5/ffffff?text=DevOps+Heroes", rating: "92% Match", year: "2024", description: "Automation saves the day" },
      { id: 4, title: "Cloud Native", image: "https://via.placeholder.com/300x450/ff6b35/ffffff?text=Cloud+Native", rating: "89% Match", year: "2024", description: "Scaling to infinity" },
      { id: 5, title: "Terraform Tales", image: "https://via.placeholder.com/300x450/623ce4/ffffff?text=Terraform+Tales", rating: "94% Match", year: "2024", description: "Infrastructure as Code magic" },
    ]
  },
  {
    title: "AWS Originals",
    movies: [
      { id: 6, title: "EKS: The Series", image: "https://via.placeholder.com/300x450/ff9900/ffffff?text=EKS+Series", rating: "96% Match", year: "2024", description: "Managed Kubernetes adventures" },
      { id: 7, title: "Lambda Chronicles", image: "https://via.placeholder.com/300x450/ff9900/000000?text=Lambda+Chronicles", rating: "91% Match", year: "2024", description: "Serverless computing saga" },
      { id: 8, title: "S3 Stories", image: "https://via.placeholder.com/300x450/569a31/ffffff?text=S3+Stories", rating: "88% Match", year: "2024", description: "Object storage odyssey" },
      { id: 9, title: "VPC Voyages", image: "https://via.placeholder.com/300x450/232f3e/ffffff?text=VPC+Voyages", rating: "93% Match", year: "2024", description: "Networking adventures" },
    ]
  },
  {
    title: "DevOps Documentaries",
    movies: [
      { id: 10, title: "CI/CD Pipeline", image: "https://via.placeholder.com/300x450/2088d1/ffffff?text=CI%2FCD+Pipeline", rating: "97% Match", year: "2024", description: "Continuous deployment mastery" },
      { id: 11, title: "Monitoring Metrics", image: "https://via.placeholder.com/300x450/e6522c/ffffff?text=Monitoring+Metrics", rating: "85% Match", year: "2024", description: "Observability insights" },
      { id: 12, title: "Security Secrets", image: "https://via.placeholder.com/300x450/dd344c/ffffff?text=Security+Secrets", rating: "92% Match", year: "2024", description: "Protecting cloud infrastructure" },
    ]
  },
  {
    title: "Kubernetes Collection",
    movies: [
      { id: 13, title: "Pod People", image: "https://via.placeholder.com/300x450/326ce5/ffffff?text=Pod+People", rating: "90% Match", year: "2024", description: "Life inside containers" },
      { id: 14, title: "Helm Heroes", image: "https://via.placeholder.com/300x450/0f1689/ffffff?text=Helm+Heroes", rating: "94% Match", year: "2024", description: "Package management adventures" },
      { id: 15, title: "Service Mesh", image: "https://via.placeholder.com/300x450/466bb0/ffffff?text=Service+Mesh", rating: "87% Match", year: "2024", description: "Microservices communication" },
    ]
  }
];

function App() {
  const [systemInfo, setSystemInfo] = useState({
    environment: 'production',
    podName: 'Loading...',
    podIP: 'Loading...',
    nodeName: 'Loading...',
    namespace: 'Loading...'
  });

  useEffect(() => {
    // Simulate fetching system info (in real app, this would be an API call)
    const fetchSystemInfo = () => {
      // In production, this would fetch from a backend endpoint that reads K8s metadata
      setSystemInfo({
        environment: process.env.REACT_APP_ENVIRONMENT || 'production',
        podName: process.env.REACT_APP_POD_NAME || 'streamflix-pod-' + Math.random().toString(36).substr(2, 5),
        podIP: process.env.REACT_APP_POD_IP || '10.0.' + Math.floor(Math.random() * 255) + '.' + Math.floor(Math.random() * 255),
        nodeName: process.env.REACT_APP_NODE_NAME || 'ip-10-0-' + Math.floor(Math.random() * 255) + '-' + Math.floor(Math.random() * 255) + '.ec2.internal',
        namespace: process.env.REACT_APP_NAMESPACE || 'default'
      });
    };

    fetchSystemInfo();
    
    // Update system info every 30 seconds to show it's dynamic
    const interval = setInterval(fetchSystemInfo, 30000);
    
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="App">
      <Header systemInfo={systemInfo} />
      <Hero />
      
      <main className="main-content">
        {movieCategories.map((category, index) => (
          <MovieRow
            key={category.title}
            title={category.title}
            movies={category.movies}
            delay={index * 0.1}
          />
        ))}
      </main>
      
      <Footer systemInfo={systemInfo} />
    </div>
  );
}

export default App;