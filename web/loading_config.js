// Simple loading screen controller - no hardcoded timers
window.flutterReady = false;

// Function called by Flutter when app is ready
window.setFlutterReady = function() {
  window.flutterReady = true;
  console.log('🎯 Flutter is ready! Hiding loading screen...');
  window.hideLoadingScreen();
};

// Function to hide the loading screen immediately
window.hideLoadingScreen = function() {
  const loadingScreen = document.getElementById('loading-screen');
  if (!loadingScreen || loadingScreen.classList.contains('hidden')) return;
  
  console.log('🎭 Starting fade out animation...');
  loadingScreen.style.animation = 'fadeOut 800ms ease-out forwards';
  
  setTimeout(() => {
    console.log('✅ Loading screen hidden');
    loadingScreen.classList.add('hidden');
  }, 800);
};
