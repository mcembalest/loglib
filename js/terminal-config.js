// Single source of truth for terminal configuration
(function() {
    const hostname = window.location.hostname;
    const isLocalDev = hostname === 'localhost' || hostname === '127.0.0.1';
    
    window.terminalConfig = {
        url: isLocalDev 
            ? 'http://localhost:7681'
            : 'https://terminal.maxcembalest.com',
        port: 7681,
        debug: isLocalDev,
        hostname: hostname,
        isLocalDev: isLocalDev
    };

    // Debug logging function
    window.terminalConfig.log = function(message) {
        if (this.debug) {
            console.log('[Terminal]', message);
        }
    };
    
    // Log the configuration on load for debugging
    if (window.terminalConfig.debug) {
        console.log('[Terminal] Configuration loaded:', {
            hostname: hostname,
            isLocalDev: isLocalDev,
            url: window.terminalConfig.url
        });
    }
})();
