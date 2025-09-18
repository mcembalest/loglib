// Terminal configuration
window.terminalConfig = {
    url: window.location.hostname === 'localhost' ? 'http://localhost:7681' :
       'wss://terminal.maxcembalest.com',    
    port: 7681,    
    debug: window.location.hostname === 'localhost'
};

// Helper to log debug messages
window.terminalConfig.log = function(message) {
    if (this.debug) {
        console.log('[Terminal]', message);
    }
};