import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'https://api.mobill.com';
const ACCESS_TOKEN_KEY = 'mobill_access_token';
const REFRESH_TOKEN_KEY = 'mobill_refresh_token';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface LoginResponse {
  access: string;
  refresh: string;
}

export interface TokenRefreshResponse {
  access: string;
}

class AuthServiceClass {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  async initialize(): Promise<void> {
    this.accessToken = await AsyncStorage.getItem(ACCESS_TOKEN_KEY);
    this.refreshToken = await AsyncStorage.getItem(REFRESH_TOKEN_KEY);
  }

  async login(credentials: LoginCredentials): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/users/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(credentials),
      });

      if (!response.ok) {
        throw new Error(`Login failed: ${response.status}`);
      }

      const data: LoginResponse = await response.json();

      await this.storeTokens(data.access, data.refresh);

      return true;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  }

  async refreshAccessToken(): Promise<boolean> {
    if (!this.refreshToken) {
      return false;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/users/token/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          refresh: this.refreshToken,
        }),
      });

      if (!response.ok) {
        await this.logout();
        return false;
      }

      const data: TokenRefreshResponse = await response.json();

      await this.storeTokens(data.access, this.refreshToken!);

      return true;
    } catch (error) {
      console.error('Token refresh error:', error);
      await this.logout();
      return false;
    }
  }

  async getValidAccessToken(): Promise<string | null> {
    if (!this.accessToken) {
      return null;
    }

    try {
      const payload = JSON.parse(atob(this.accessToken.split('.')[1]));
      const currentTime = Math.floor(Date.now() / 1000);

      if (payload.exp && payload.exp < currentTime + 300) {
        const refreshed = await this.refreshAccessToken();
        if (!refreshed) {
          return null;
        }
      }

      return this.accessToken;
    } catch (error) {
      console.error('Error validating token:', error);
      return null;
    }
  }

  async logout(): Promise<void> {
    this.accessToken = null;
    this.refreshToken = null;

    await AsyncStorage.multiRemove([ACCESS_TOKEN_KEY, REFRESH_TOKEN_KEY]);
  }

  isLoggedIn(): boolean {
    return !!this.refreshToken;
  }

  getAccessToken(): string | null {
    return this.accessToken;
  }

  private async storeTokens(accessToken: string, refreshToken: string): Promise<void> {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;

    await AsyncStorage.multiSet([
      [ACCESS_TOKEN_KEY, accessToken],
      [REFRESH_TOKEN_KEY, refreshToken],
    ]);
  }
}

const AuthService = new AuthServiceClass();
export default AuthService;