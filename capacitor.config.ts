import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.keepintouch.crm',
  appName: 'Keep In Touch',
  webDir: 'dist',
  server: {
    url: 'https://4d5b5815-528a-4309-9e03-ead2012f475e.lovableproject.com?forceHideBadge=true',
    cleartext: true
  },
  ios: {
    contentInset: 'automatic',
    preferredContentMode: 'mobile',
    scheme: 'App'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      launchAutoHide: true,
      backgroundColor: '#1A1A2E',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true
    },
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert']
    },
    Keyboard: {
      resize: 'body',
      resizeOnFullScreen: true
    },
    StatusBar: {
      style: 'dark',
      backgroundColor: '#1A1A2E'
    }
  }
};

export default config;
