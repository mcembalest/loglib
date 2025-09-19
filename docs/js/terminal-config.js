window.terminalConfig = {
    url: window.location.hostname === 'localhost'
        ? 'http://localhost:7681'
        : 'https://terminal.maxcembalest.com',
    port: 7681,
    debug: window.location.hostname === 'localhost'
};

window.terminalConfig.log = function(message) {
    if (this.debug) {
        console.log('[Terminal]', message);
    }
};
