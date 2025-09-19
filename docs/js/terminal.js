(() => {
    const storageKey = 'terminal-visible';
    
    // Get terminal URL from config - config is the single source of truth
    const getTerminalUrl = () => {
        if (!window.terminalConfig || !window.terminalConfig.url) {
            console.error('[Terminal] terminalConfig.url not found. Make sure terminal-config.js is loaded first.');
            return 'http://localhost:7681'; // fallback for development
        }
        return window.terminalConfig.url;
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
        const terminalUrl = getTerminalUrl();
        iframe.src = terminalUrl;
        iframe.className = 'terminal-iframe';
        iframe.title = 'Embedded terminal';
        iframe.addEventListener('error', () => handleIframeError(iframe));
        
        // Debug logging
        if (window.terminalConfig && window.terminalConfig.log) {
            window.terminalConfig.log(`Creating terminal iframe with URL: ${terminalUrl}`);
        }
        
        panel.innerHTML = `
            <div class="terminal-header">
                <span class="terminal-title">loglibrary terminal</span>
                <button type="button" class="terminal-toggle" aria-label="Hide terminal">Close</button>
            </div>
            <div class="terminal-body"></div>
            <div class="terminal-resize-handle-tr"></div>
            <div class="terminal-resize-handle-bl"></div>
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

        // Add resize functionality
        addResizeHandlers(panel);
        
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

    function addResizeHandlers(panel) {
        const handles = [
            { element: panel, cursor: 'nw-resize', corner: 'top-left' },
            { element: panel.querySelector('.terminal-resize-handle-tr'), cursor: 'ne-resize', corner: 'top-right' },
            { element: panel.querySelector('.terminal-resize-handle-bl'), cursor: 'sw-resize', corner: 'bottom-left' }
        ];

        handles.forEach(({ element, cursor, corner }) => {
            let isResizing = false;
            let startX, startY, startWidth, startHeight, startLeft, startTop;

            element.addEventListener('mousedown', (e) => {
                // Only resize on corner handles, not the main panel
                if (element === panel && corner === 'top-left') {
                    // Check if we're actually in the top-left corner (20px x 20px)
                    const rect = panel.getBoundingClientRect();
                    if (e.clientX - rect.left > 20 || e.clientY - rect.top > 20) {
                        return; // Not in the corner, don't resize
                    }
                }

                isResizing = true;
                startX = e.clientX;
                startY = e.clientY;
                startWidth = parseInt(window.getComputedStyle(panel).width, 10);
                startHeight = parseInt(window.getComputedStyle(panel).height, 10);
                startLeft = parseInt(window.getComputedStyle(panel).right, 10);
                startTop = parseInt(window.getComputedStyle(panel).bottom, 10);

                document.addEventListener('mousemove', handleMouseMove);
                document.addEventListener('mouseup', handleMouseUp);
                e.preventDefault();
            });

            const handleMouseMove = (e) => {
                if (!isResizing) return;

                const deltaX = e.clientX - startX;
                const deltaY = e.clientY - startY;

                switch (corner) {
                    case 'top-left':
                        // Bottom-right stays pinned, extend up and left
                        const newWidth = startWidth - deltaX;
                        const newHeight = startHeight - deltaY;

                        if (newWidth >= 320 && newHeight >= 220) {
                            panel.style.width = newWidth + 'px';
                            panel.style.height = newHeight + 'px';
                        }
                        break;

                    case 'top-right':
                        // Bottom-right stays pinned, extend up only
                        const newHeightTR = startHeight - deltaY;

                        if (newHeightTR >= 220) {
                            panel.style.height = newHeightTR + 'px';
                        }
                        break;

                    case 'bottom-left':
                        // Bottom-right stays pinned, extend left only
                        const newWidthBL = startWidth - deltaX;

                        if (newWidthBL >= 320) {
                            panel.style.width = newWidthBL + 'px';
                        }
                        break;
                }
            };

            const handleMouseUp = () => {
                isResizing = false;
                document.removeEventListener('mousemove', handleMouseMove);
                document.removeEventListener('mouseup', handleMouseUp);
            };
        });
    }
})();
