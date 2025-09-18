window.terminalConfig = {
    url: 'wss://terminal.maxcembalest.com',
    port: 7681,
    debug: window.location.hostname === 'localhost'
};

window.terminalConfig.log = function(message) {
    if (this.debug) {
        console.log('[Terminal]', message);
    }
};
