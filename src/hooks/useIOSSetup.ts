import { useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import { StatusBar, Style } from '@capacitor/status-bar';
import { Keyboard } from '@capacitor/keyboard';
import { SplashScreen } from '@capacitor/splash-screen';

export const useIOSSetup = () => {
  useEffect(() => {
    if (!Capacitor.isNativePlatform()) {
      return;
    }

    const setupIOS = async () => {
      try {
        // Hide splash screen after app is ready
        await SplashScreen.hide();

        // Configure status bar
        if (Capacitor.getPlatform() === 'ios') {
          await StatusBar.setStyle({ style: Style.Dark });
        }

        // Setup keyboard listeners
        Keyboard.addListener('keyboardWillShow', (info) => {
          document.body.style.setProperty('--keyboard-height', `${info.keyboardHeight}px`);
        });

        Keyboard.addListener('keyboardWillHide', () => {
          document.body.style.setProperty('--keyboard-height', '0px');
        });
      } catch (error) {
        console.error('Error setting up iOS:', error);
      }
    };

    setupIOS();

    return () => {
      Keyboard.removeAllListeners();
    };
  }, []);
};
