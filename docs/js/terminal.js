(() => {
    const storageKey = 'terminal-visible';
    
    // Get terminal URL from config or default
    const getTerminalUrl = () => {
        const config = window.terminalConfig || {};
        return config.url || (window.location.hostname === 'localhost' ? 'http://localhost:7681' : `${window.location.protocol}//${window.location.hostname}:7681`);
    };

    const mount = () => {
        const ui = ensureTerminal();
        disableTransitions(ui);
        attach(ui);
        syncFromStorage(ui);
        enableTransitions(ui);
        
        // Add debug logging
        if (window.terminalConfig && window.terminalConfig.debug) {
            console.log('[Terminal] Mounted, iframe connected:', !!ui.iframe?.isConnected);
        }
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', mount);
    } else {
        mount();
    }

    if (window.document$ && typeof window.document$.subscribe === 'function') {
        window.document$.subscribe(mount);
    }

    function ensureTerminal() {
        // With instant loading, terminal should persist automatically
        // Only create once and reuse the same iframe
        if (window.__loglibraryTerminal && window.__loglibraryTerminal.panel) {
            return window.__loglibraryTerminal;
        }

        // Create new terminal only if none exists
        const panel = document.createElement('div');
        panel.id = 'terminal-panel';
        panel.className = 'terminal-panel terminal-hidden terminal-no-transition';
        panel.setAttribute('aria-hidden', 'true');
        
        // Create iframe only once and reuse it
        const iframe = document.createElement('iframe');
        iframe.src = getTerminalUrl();
        iframe.className = 'terminal-iframe';
        iframe.title = 'Embedded terminal';
        iframe.addEventListener('error', () => handleIframeError(iframe));
        
        panel.innerHTML = `
            <div class="terminal-header">
                <span class="terminal-title">Terminal</span>
                <button type="button" class="terminal-toggle" aria-label="Hide terminal">Close</button>
            </div>
            <div class="terminal-body"></div>
        `;
        
        // Append the iframe to the terminal body
        panel.querySelector('.terminal-body').appendChild(iframe);

        const launcher = document.createElement('button');
        launcher.id = 'terminal-launcher';
        launcher.type = 'button';
        launcher.className = 'terminal-launcher terminal-no-transition';
        launcher.setAttribute('aria-label', 'Launch terminal');
        launcher.setAttribute('aria-expanded', 'false');

        const toggle = panel.querySelector('.terminal-toggle');
        launcher.addEventListener('click', () => setVisible(true, panel, launcher, true));
        toggle.addEventListener('click', () => setVisible(false, panel, launcher, true));
        
        const keydownHandler = event => {
            if (event.key === 'Escape' && !panel.classList.contains('terminal-hidden')) {
                setVisible(false, panel, launcher, true);
            }
        };
        window.addEventListener('keydown', keydownHandler);

        window.__loglibraryTerminal = { 
            panel, 
            launcher, 
            iframe,
            keydownHandler,
            cleanup: () => {
                window.removeEventListener('keydown', keydownHandler);
            }
        };
        
        return window.__loglibraryTerminal;
    }

    function attach({ panel, launcher }) {
        if (!panel.isConnected) {
            document.body.appendChild(panel);
        }
        if (!launcher.isConnected) {
            document.body.appendChild(launcher);
        }
    }

    function syncFromStorage({ panel, launcher }) {
        try {
            const shouldShow = window.localStorage.getItem(storageKey) === 'true';
            setVisible(shouldShow, panel, launcher, false);
        } catch (e) {
            console.warn('Terminal: localStorage not available, terminal state will not persist');
        }
    }
    
    function handleIframeError(iframe) {
        const errorMsg = document.createElement('div');
        errorMsg.className = 'terminal-error';
        errorMsg.innerHTML = `
            <p>Terminal connection failed</p>
            <p>Make sure the terminal server is running on port 7681</p>
            <button onclick="location.reload()">Retry</button>
        `;
        iframe.parentNode.replaceChild(errorMsg, iframe);
    }

    function setVisible(visible, panel, launcher, persist) {
        if (visible) {
            panel.classList.remove('terminal-hidden');
            panel.setAttribute('aria-hidden', 'false');
            launcher.classList.add('terminal-launcher-hidden');
            launcher.setAttribute('aria-expanded', 'true');
            if (persist) {
                try {
                    window.localStorage.setItem(storageKey, 'true');
                } catch (e) {
                    console.warn('Terminal: localStorage not available');
                }
            }
        } else {
            panel.classList.add('terminal-hidden');
            panel.setAttribute('aria-hidden', 'true');
            launcher.classList.remove('terminal-launcher-hidden');
            launcher.setAttribute('aria-expanded', 'false');
            if (persist) {
                try {
                    window.localStorage.setItem(storageKey, 'false');
                } catch (e) {
                    console.warn('Terminal: localStorage not available');
                }
            }
        }
    }

    function disableTransitions({ panel, launcher }) {
        panel.classList.add('terminal-no-transition');
        launcher.classList.add('terminal-no-transition');
    }

    function enableTransitions({ panel, launcher }) {
        requestAnimationFrame(() => {
            panel.classList.remove('terminal-no-transition');
            launcher.classList.remove('terminal-no-transition');
        });
    }
})();
