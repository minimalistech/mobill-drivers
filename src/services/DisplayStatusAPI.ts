import AuthService from './AuthService';
import AppVersionService from './AppVersionService';

const API_BASE_URL = 'https://api.mobill.com';

export type DisplayStatus = 'turned_on' | 'turned_off' | 'disconnected' | 'reconnected';

export interface DisplayStatusResponse {
  id: number;
  driver_id: number;
  driver_name: string;
  status: DisplayStatus;
  timestamp: string;
  notes: string | null;
}

class DisplayStatusAPIClass {
  /**
   * Report display status to backend
   * @param status Display status event
   * @param notes Optional notes for context
   */
  async reportStatus(status: DisplayStatus, notes?: string): Promise<DisplayStatusResponse | null> {
    try {
      const accessToken = await AuthService.getValidAccessToken();
      if (!accessToken) {
        console.error('📊 No valid access token available for display status');
        return null;
      }

      const url = `${API_BASE_URL}/api/v1/core/display-status`;

      // Get app version headers
      const versionHeaders = await AppVersionService.getVersionHeaders();

      // Build request body
      const body: { status: DisplayStatus; notes?: string } = { status };
      if (notes) {
        body.notes = notes;
      }

      console.log(`📊 DISPLAY-STATUS API CALL: ${status}${notes ? ` - ${notes}` : ''}`);
      console.log(`📍 URL: ${url}`);
      console.log(`🔑 Authorization: Bearer ${accessToken.substring(0, 20)}...`);
      console.log(`📱 App: ${versionHeaders['X-App-Version']} (${versionHeaders['X-App-Platform']}) build ${versionHeaders['X-App-Build']}`);

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          ...versionHeaders,
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`📊 Display status API failed: ${response.status} - ${errorText}`);
        return null;
      }

      const data: DisplayStatusResponse = await response.json();
      console.log(`✅ Display status reported successfully: ${data.status} (ID: ${data.id})`);
      return data;
    } catch (error) {
      console.error('📊 Error reporting display status:', error);
      return null;
    }
  }

  /**
   * Report display turned on (user manually turned on)
   */
  async reportTurnedOn(): Promise<DisplayStatusResponse | null> {
    return this.reportStatus('turned_on');
  }

  /**
   * Report display turned off (user manually turned off)
   */
  async reportTurnedOff(): Promise<DisplayStatusResponse | null> {
    return this.reportStatus('turned_off');
  }

  /**
   * Report display disconnected (unintended hardware disconnect)
   */
  async reportDisconnected(notes?: string): Promise<DisplayStatusResponse | null> {
    return this.reportStatus('disconnected', notes || 'Bluetooth connection lost');
  }

  /**
   * Report display reconnected (after unintended disconnect)
   */
  async reportReconnected(automatic: boolean = false): Promise<DisplayStatusResponse | null> {
    const notes = automatic ? 'Automatic reconnection successful' : 'Manual reconnection';
    return this.reportStatus('reconnected', notes);
  }
}

const DisplayStatusAPI = new DisplayStatusAPIClass();
export default DisplayStatusAPI;
