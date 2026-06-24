import AuthService from './AuthService';
import AppVersionService from './AppVersionService';
import type { AdContent } from './AdService';

const API_BASE_URL = 'https://api.mobill.com';

/**
 * Single element of the GET /api/v1/core/campaigns-list response.
 *
 * NOTE: this is a reporting view. It does NOT contain ad content
 * (no image URL, text, programType, or display size). Use
 * fetchCampaignContent() for playable content (Phase 2 — pending backend).
 */
export interface CampaignListItem {
  id: string; // campaign UUID (used verbatim in the content endpoint path)
  market: string | null; // market city name (not the ID)
  active: boolean;
  description: string;
  start: string | null; // ISO date YYYY-MM-DD
  duration: number; // days
  end_date: string | null; // ISO date
  ad: string | null; // ad name
  total_spots: number;
  today_spots: number;
  daily_budget: number;
  daily_budget_spent: number;
  total_budget_spent: number;
}

export interface FetchCampaignsOptions {
  market?: number; // market ID
  active?: boolean;
}

class CampaignServiceClass {
  /**
   * Fetch the full campaigns list (reporting view, all advertisers).
   * Returns [] on any error (logs it). Filters are applied server-side.
   */
  async fetchCampaigns(opts: FetchCampaignsOptions = {}): Promise<CampaignListItem[]> {
    try {
      const accessToken = await AuthService.getValidAccessToken();
      if (!accessToken) {
        console.error('🐞 CampaignService: no valid access token available');
        return [];
      }

      // Note: this route has NO trailing slash.
      let url = `${API_BASE_URL}/api/v1/core/campaigns-list`;

      const params = new URLSearchParams();
      if (typeof opts.market === 'number' && !Number.isNaN(opts.market)) {
        params.append('market', opts.market.toString());
      }
      if (typeof opts.active === 'boolean') {
        // Backend treats anything other than "true" as false; only send when explicitly filtering.
        params.append('active', opts.active ? 'true' : 'false');
      }
      const query = params.toString();
      if (query) {
        url += `?${query}`;
      }

      const versionHeaders = await AppVersionService.getVersionHeaders();

      console.log(`🐞 CampaignService: GET ${url}`);

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          ...versionHeaders,
        },
      });

      if (!response.ok) {
        // Surface the server's error body (e.g. the documented 500
        // {"error": "..."}) so backend failures are diagnosable from logs.
        const body = await response.text().catch(() => '');
        throw new Error(`campaigns-list fetch failed: ${response.status} ${body}`);
      }

      const data = await response.json();
      if (!Array.isArray(data)) {
        console.error('🐞 CampaignService: unexpected response shape (expected array)');
        return [];
      }

      console.log(`🐞 CampaignService: received ${data.length} campaigns`);
      return data as CampaignListItem[];
    } catch (error) {
      console.error('🐞 CampaignService: error fetching campaigns:', error);
      return [];
    }
  }

  /**
   * Fetch playable ad content for a specific campaign.
   *
   * GET /api/v1/core/campaigns/<id>/content -> { content: AdContent }
   * Returns null on 404 / no content / any error (logged) so the debug
   * screen can show a "no content" state instead of crashing.
   */
  async fetchCampaignContent(id: string): Promise<AdContent | null> {
    try {
      const accessToken = await AuthService.getValidAccessToken();
      if (!accessToken) {
        console.error('🐞 CampaignService: no valid access token for content fetch');
        return null;
      }

      // No trailing slash, matching the campaigns-list convention.
      const url = `${API_BASE_URL}/api/v1/core/campaigns/${encodeURIComponent(id)}/content`;
      const versionHeaders = await AppVersionService.getVersionHeaders();

      console.log(`🐞 CampaignService: GET ${url}`);

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          ...versionHeaders,
        },
      });

      if (!response.ok) {
        // 404 / 409 = no content for this campaign; treat as "no content".
        const body = await response.text().catch(() => '');
        console.warn(`🐞 CampaignService: content fetch returned ${response.status} ${body}`);
        return null;
      }

      const data = await response.json();
      const content = data?.content;
      if (!content || typeof content !== 'object') {
        console.warn('🐞 CampaignService: response had no content object');
        return null;
      }

      return content as AdContent;
    } catch (error) {
      console.error('🐞 CampaignService: error fetching campaign content:', error);
      return null;
    }
  }
}

const CampaignService = new CampaignServiceClass();
export default CampaignService;
