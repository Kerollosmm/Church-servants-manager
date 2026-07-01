/* Stillroom — Interactive Client Logic */

document.addEventListener('DOMContentLoaded', () => {
    // 1. Initialize Reveal on Scroll
    initScrollReveal();

    // 2. Mobile Menu Navigation
    initMobileNav();

    // 3. Daily Rituals Switcher
    initRitualSwitcher();

    // 4. Web Audio Synthesizer (Ambient Soundscape)
    initAmbientAudio();

    // 5. Mock Invitation Form
    initInvitationForm();
});

/**
 * 1. Intersection Observer for Scroll Reveals
 */
function initScrollReveal() {
    const revealElements = document.querySelectorAll('.reveal');
    
    const observerOptions = {
        root: null, // viewport
        rootMargin: '0px',
        threshold: 0.15 // trigger when 15% visible
    };
    
    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Unobserve once shown
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    revealElements.forEach(element => {
        revealObserver.observe(element);
    });
}

/**
 * 2. Mobile Navigation Toggle
 */
function initMobileNav() {
    const navToggle = document.querySelector('.mobile-nav-toggle');
    const navLinks = document.querySelector('.nav-links');
    
    if (navToggle && navLinks) {
        navToggle.addEventListener('click', () => {
            navLinks.classList.toggle('open');
            
            // Animation for toggle lines
            const spans = navToggle.querySelectorAll('span');
            if (navLinks.classList.contains('open')) {
                spans[0].style.transform = 'translateY(7px) rotate(45deg)';
                spans[1].style.opacity = '0';
                spans[2].style.transform = 'translateY(-7px) rotate(-45deg)';
            } else {
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            }
        });
        
        // Close menu on link click
        navLinks.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', () => {
                navLinks.classList.remove('open');
                const spans = navToggle.querySelectorAll('span');
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            });
        });
    }
}

/**
 * 3. Daily Rituals Switcher
 */
function initRitualSwitcher() {
    const switcherItems = document.querySelectorAll('.ritual-nav-item');
    const displayCards = document.querySelectorAll('.ritual-card-content');
    const soundStatus = document.querySelector('.audio-status');
    const soundDesc = document.querySelector('.audio-desc');
    
    // Scent and sound details mapped to each ritual
    const ritualDetails = {
        morning: {
            title: 'Listen to the Morning Soundscape',
            desc: '10-Minute Dawn Chorus & Low Drone'
        },
        midday: {
            title: 'Listen to the Midday Soundscape',
            desc: '10-Minute Wind Chime & Cleansing Drone'
        },
        evening: {
            title: 'Listen to the Evening Soundscape',
            desc: '10-Minute Sandalwood Twilight Drone'
        }
    };
    
    switcherItems.forEach(item => {
        item.addEventListener('click', () => {
            const selectedRitual = item.getAttribute('data-ritual');
            
            // Toggle active nav class
            switcherItems.forEach(i => i.classList.remove('active'));
            item.classList.add('active');
            
            // Toggle active card display with smooth fade
            displayCards.forEach(card => {
                card.classList.remove('active');
                if (card.getAttribute('id') === `ritual-${selectedRitual}`) {
                    card.classList.add('active');
                }
            });
            
            // Update audio status details if audio isn't already playing
            if (!audioContext || audioContext.state !== 'running') {
                if (soundStatus && soundDesc) {
                    soundStatus.textContent = ritualDetails[selectedRitual].title;
                    soundDesc.textContent = ritualDetails[selectedRitual].desc;
                }
            }
            
            // Store current ritual for the audio generator
            currentRitualType = selectedRitual;
            if (audioContext && audioContext.state === 'running') {
                updateSynthFrequency(selectedRitual);
            }
        });
    });
}

/**
 * 4. Web Audio API - Synthetic Ambient Drone
 * Generates wabi-sabi binaural beats (theta waves for relaxation)
 */
let audioContext = null;
let masterGain = null;
let oscLeft = null;
let oscRight = null;
let oscAtmosphere = null;
let lpFilter = null;
let lfo = null;
let currentRitualType = 'morning';

function initAmbientAudio() {
    const btnSound = document.getElementById('btn-sound');
    const iconPlay = document.querySelector('.icon-play');
    const iconPause = document.querySelector('.icon-pause');
    const audioWave = document.querySelector('.audio-wave');
    const soundStatus = document.querySelector('.audio-status');
    
    if (!btnSound) return;
    
    btnSound.addEventListener('click', () => {
        // Initialize or resume AudioContext
        if (!audioContext) {
            setupAudioEngine();
        }
        
        if (audioContext.state === 'suspended') {
            audioContext.resume();
            fadeInAudio();
            iconPlay.classList.add('hidden');
            iconPause.classList.remove('hidden');
            audioWave.classList.add('playing');
            if (soundStatus) soundStatus.textContent = 'Playing Restorative Drone...';
        } else if (audioContext.state === 'running') {
            fadeOutAudio(() => {
                audioContext.suspend();
                iconPlay.classList.remove('hidden');
                iconPause.classList.add('hidden');
                audioWave.classList.remove('playing');
                if (soundStatus) {
                    const ritualNames = {
                        morning: 'Morning Soundscape',
                        midday: 'Midday Soundscape',
                        evening: 'Evening Soundscape'
                    };
                    soundStatus.textContent = `Listen to the ${ritualNames[currentRitualType]}`;
                }
            });
        }
    });
}

/**
 * Sets up Audio Synthesis nodes
 * Low-frequency binaural drone: Left 100Hz, Right 104.5Hz (creates a 4.5Hz theta beat)
 * Muffled noise/LFO filter sweeps for organic timber cabin wind sound.
 */
function setupAudioEngine() {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
    
    // LP Filter to make everything warm and soft (shave off all harsh highs)
    lpFilter = audioContext.createBiquadFilter();
    lpFilter.type = 'lowpass';
    lpFilter.frequency.setValueAtTime(140, audioContext.currentTime); // very low cutoff
    lpFilter.Q.setValueAtTime(1.5, audioContext.currentTime);
    
    // Master Gain node
    masterGain = audioContext.createGain();
    masterGain.gain.setValueAtTime(0, audioContext.currentTime); // start silent
    
    // Split stereo output for binaural beats
    const stereoMerger = audioContext.createChannelMerger(2);
    
    // Oscillator 1 (Left Channel)
    oscLeft = audioContext.createOscillator();
    oscLeft.type = 'sine';
    oscLeft.frequency.setValueAtTime(98.0, audioContext.currentTime); // G2 note
    
    const gainLeft = audioContext.createGain();
    gainLeft.gain.setValueAtTime(0.5, audioContext.currentTime);
    
    // Oscillator 2 (Right Channel)
    oscRight = audioContext.createOscillator();
    oscRight.type = 'sine';
    // Add 4.5Hz offset for Theta brain wave stimulation (relaxing)
    oscRight.frequency.setValueAtTime(102.5, audioContext.currentTime);
    
    const gainRight = audioContext.createGain();
    gainRight.gain.setValueAtTime(0.5, audioContext.currentTime);
    
    // Connect oscillators to corresponding stereo channels
    oscLeft.connect(gainLeft).connect(stereoMerger, 0, 0);
    oscRight.connect(gainRight).connect(stereoMerger, 0, 1);
    
    // Atmosphere Layer (Adds organic wind/warmth)
    oscAtmosphere = audioContext.createOscillator();
    oscAtmosphere.type = 'triangle';
    oscAtmosphere.frequency.setValueAtTime(147.0, audioContext.currentTime); // D3 note (harmonic fifth)
    
    const gainAtmosphere = audioContext.createGain();
    gainAtmosphere.gain.setValueAtTime(0.18, audioContext.currentTime);
    oscAtmosphere.connect(gainAtmosphere).connect(lpFilter);
    
    // Add LFO to modulate filter cutoff slowly for organic breathing effect
    lfo = audioContext.createOscillator();
    lfo.type = 'sine';
    lfo.frequency.setValueAtTime(0.08, audioContext.currentTime); // extremely slow modulation (12 seconds per cycle)
    
    const lfoGain = audioContext.createGain();
    lfoGain.gain.setValueAtTime(45, audioContext.currentTime); // range of modulation
    
    lfo.connect(lfoGain).connect(lpFilter.frequency);
    
    // Connect stereo merger to lowpass filter
    stereoMerger.connect(lpFilter);
    
    // Connect filter to master gain and then destination
    lpFilter.connect(masterGain).connect(audioContext.destination);
    
    // Start all sound generators
    oscLeft.start();
    oscRight.start();
    oscAtmosphere.start();
    lfo.start();
    
    // Set frequency based on active ritual
    updateSynthFrequency(currentRitualType);
}

/**
 * Smooth transition between sound frequencies when rituals shift
 */
function updateSynthFrequency(ritualType) {
    if (!audioContext) return;
    
    const t = audioContext.currentTime;
    
    if (ritualType === 'morning') {
        // Morning: Grounding but alert G2 (98Hz) / D3 (147Hz)
        oscLeft.frequency.exponentialRampToValueAtTime(98.0, t + 2);
        oscRight.frequency.exponentialRampToValueAtTime(102.5, t + 2);
        oscAtmosphere.frequency.exponentialRampToValueAtTime(147.0, t + 2);
        lpFilter.frequency.setValueAtTime(140, t);
    } else if (ritualType === 'midday') {
        // Midday: Cleansing, slightly higher A2 (110Hz) / E3 (165Hz)
        oscLeft.frequency.exponentialRampToValueAtTime(110.0, t + 2);
        oscRight.frequency.exponentialRampToValueAtTime(114.5, t + 2);
        oscAtmosphere.frequency.exponentialRampToValueAtTime(165.0, t + 2);
        lpFilter.frequency.setValueAtTime(165, t);
    } else if (ritualType === 'evening') {
        // Evening: Deep, sedative E2 (82.4Hz) / B2 (123.5Hz)
        oscLeft.frequency.exponentialRampToValueAtTime(82.4, t + 2);
        oscRight.frequency.exponentialRampToValueAtTime(86.9, t + 2);
        oscAtmosphere.frequency.exponentialRampToValueAtTime(123.5, t + 2);
        lpFilter.frequency.setValueAtTime(110, t);
    }
}

function fadeInAudio() {
    if (!masterGain) return;
    masterGain.gain.setValueAtTime(masterGain.gain.value, audioContext.currentTime);
    masterGain.gain.linearRampToValueAtTime(0.65, audioContext.currentTime + 1.8);
}

function fadeOutAudio(callback) {
    if (!masterGain) return;
    masterGain.gain.setValueAtTime(masterGain.gain.value, audioContext.currentTime);
    masterGain.gain.linearRampToValueAtTime(0.0, audioContext.currentTime + 0.8);
    setTimeout(callback, 850);
}

/**
 * 5. Invitation Form Submission Handler (Mock API)
 */
function initInvitationForm() {
    const form = document.getElementById('newsletter-form');
    
    if (form) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            
            const emailInput = document.getElementById('email');
            const submitBtn = form.querySelector('button[type="submit"]');
            
            if (!emailInput || !submitBtn) return;
            
            const originalBtnText = submitBtn.textContent;
            
            // UI Loading state
            submitBtn.disabled = true;
            submitBtn.textContent = 'Verifying...';
            submitBtn.style.opacity = '0.7';
            submitBtn.style.cursor = 'wait';
            
            // Mock network call
            setTimeout(() => {
                // Success state response
                const email = emailInput.value;
                localStorage.setItem('stillroom_invite', JSON.stringify({
                    email: email,
                    date: new Date().toISOString()
                }));
                
                // Replace the form container content with success message
                const parentCard = form.closest('.invitation-card');
                if (parentCard) {
                    parentCard.style.opacity = '0';
                    setTimeout(() => {
                        parentCard.innerHTML = `
                            <div class="invitation-header" style="padding: 20px 0;">
                                <span class="invitation-tag" style="animation: fade-in 0.8s ease;">Invitation Accepted</span>
                                <h2 class="invitation-title" style="font-size: 2rem;">A note has been prepared for you.</h2>
                                <p class="invitation-desc text-muted" style="margin-top: 15px; font-weight: 300;">
                                    We have recorded your email: <strong>${email}</strong>.<br>
                                    As the Autumn Equinox approaches, we will send guidelines on preparing your space and details to finalize your membership. Welcome to the Stillroom.
                                </p>
                            </div>
                        `;
                        parentCard.style.opacity = '1';
                        // Re-trigger scroll reveal values just in case
                        parentCard.style.transform = 'none';
                    }, 400);
                }
            }, 1800);
        });
    }
}
