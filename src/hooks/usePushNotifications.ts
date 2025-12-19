import { useEffect, useState, useCallback, useRef } from 'react';
import { Capacitor } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import { PushNotifications, Token, PushNotificationSchema, ActionPerformed } from '@capacitor/push-notifications';

export const usePushNotifications = () => {
  const [token, setToken] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<PushNotificationSchema[]>([]);
  const [isRegistering, setIsRegistering] = useState(false);
  const listenersRef = useRef<PluginListenerHandle[]>([]);
  const isSetup = useRef(false);

  // Setup listeners only once - but don't auto-register
  useEffect(() => {
    if (!Capacitor.isNativePlatform() || isSetup.current) {
      return;
    }
    isSetup.current = true;

    const setupListeners = async () => {
      try {
        const registrationListener = await PushNotifications.addListener('registration', (token: Token) => {
          console.log('Push registration success, token:', token.value);
          setToken(token.value);
          setIsRegistering(false);
        });
        listenersRef.current.push(registrationListener);

        const errorListener = await PushNotifications.addListener('registrationError', (error) => {
          console.error('Push registration error:', error);
          setIsRegistering(false);
        });
        listenersRef.current.push(errorListener);

        const receivedListener = await PushNotifications.addListener('pushNotificationReceived', (notification: PushNotificationSchema) => {
          console.log('Push notification received:', notification);
          setNotifications(prev => [...prev, notification]);
        });
        listenersRef.current.push(receivedListener);

        const actionListener = await PushNotifications.addListener('pushNotificationActionPerformed', (action: ActionPerformed) => {
          console.log('Push notification action performed:', action);
        });
        listenersRef.current.push(actionListener);
      } catch (error) {
        console.error('Error setting up push notification listeners:', error);
      }
    };

    setupListeners();

    return () => {
      listenersRef.current.forEach(listener => listener.remove());
      listenersRef.current = [];
      isSetup.current = false;
    };
  }, []);

  // Manual registration function - only called on button click
  const requestPermission = useCallback(async () => {
    if (!Capacitor.isNativePlatform() || isRegistering) return;
    
    setIsRegistering(true);
    try {
      let permStatus = await PushNotifications.checkPermissions();
      
      if (permStatus.receive === 'prompt') {
        permStatus = await PushNotifications.requestPermissions();
      }
      
      if (permStatus.receive === 'granted') {
        await PushNotifications.register();
      } else {
        console.log('Push notification permission not granted');
        setIsRegistering(false);
      }
    } catch (error) {
      console.error('Error registering push notifications:', error);
      setIsRegistering(false);
    }
  }, [isRegistering]);

  return { token, notifications, requestPermission, isRegistering };
};
