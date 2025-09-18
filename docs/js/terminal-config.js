// Terminal configuration
window.terminalConfig = {
    // Development URL (localhost)
    url: window.location.hostname === 'localhost' ? 'http://localhost:7681' : 
         // Production URL (adjust as needed for your deployment)
         `${window.location.protocol}//${window.location.hostname}:7681`,
    
    // Fallback port for different environments
    port: 7681,
    
    // Enable debug logging
    debug: window.location.hostname === 'localhost'
};

// Helper to log debug messages
window.terminalConfig.log = function(message) {
    if (this.debug) {
        console.log('[Terminal]', message);
    }
};