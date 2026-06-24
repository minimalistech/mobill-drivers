/**
 * Debug Screen (hidden developer tool)
 *
 * Reached by tapping the version number on the Home screen 3x.
 *
 * - Browse / search / inspect campaigns (GET /api/v1/core/campaigns-list).
 *   Campaigns are NOT loaded until the user taps Apply.
 * - Connect to the LED display with a MINIMAL flow — scan -> connect ->
 *   displayContent — using its own lightweight BLE listeners and NONE of the
 *   production side effects HomeScreen runs on connect (no ad serving, no
 *   location tracking, no impression scanning, no backend status reports).
 * - Play sends the selected campaign's ad; Stop sends the same native
 *   command as the home screen's off button (turnOffDisplay).
 */

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Image,
  Keyboard,
  Platform,
  PermissionsAndroid,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';

import CampaignService, { type CampaignListItem } from '../services/CampaignService';
import type { AdContent } from '../services/AdService';
import { buildDisplayConfig } from '../utils/displayValidation';
import DisplayManager from '../DisplayManager';

type DebugConnState = 'disconnected' | 'scanning' | 'connecting' | 'connected';

interface DebugScreenProps {
  onClose: () => void;
}

type DebugView = 'list' | 'detail';

/**
 * Normalize a textColor into a value React Native's <Text color> accepts.
 * The backend sends an "R,G,B" triplet (e.g. "255,255,255"); RN needs
 * "rgb(...)" or hex. Pass through hex/named colors unchanged.
 */
function toCssColor(textColor: string | undefined): string {
  if (!textColor) return '#FFFFFF';
  const trimmed = textColor.trim();
  const triplet = trimmed.match(/^(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})$/);
  if (triplet) {
    return `rgb(${triplet[1]}, ${triplet[2]}, ${triplet[3]})`;
  }
  return trimmed; // already hex (#RRGGBB) or a named color
}

const DebugScreen: React.FC<DebugScreenProps> = ({ onClose }) => {
  const [view, setView] = useState<DebugView>('list');
  const [selected, setSelected] = useState<CampaignListItem | null>(null);

  const [campaigns, setCampaigns] = useState<CampaignListItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const [search, setSearch] = useState('');
  const [marketInput, setMarketInput] = useState('');
  const [activeOnly, setActiveOnly] = useState(false);

  // Whether the user has run a search yet (no auto-load on mount).
  const [hasSearched, setHasSearched] = useState(false);

  // Detail-view ad content
  const [content, setContent] = useState<AdContent | null>(null);
  const [contentLoading, setContentLoading] = useState(false);
  const [contentError, setContentError] = useState(false);
  const [sending, setSending] = useState(false);
  // Ref mirror so the (mount-once) connect listener can send the currently
  // selected ad without being re-subscribed on every content change.
  const contentRef = useRef<AdContent | null>(null);
  useEffect(() => {
    contentRef.current = content;
  }, [content]);
  // Stable handle to sendAd for the mount-once connect listener.
  const sendAdRef = useRef<((showAlerts?: boolean) => void) | null>(null);

  // Minimal debug display connection (independent of HomeScreen).
  const [connState, setConnState] = useState<DebugConnState>('disconnected');
  // Ref mirror so the (mount-once) discovery listener reads current state
  // without re-subscribing on every connState change.
  const connStateRef = useRef<DebugConnState>('disconnected');
  useEffect(() => {
    connStateRef.current = connState;
  }, [connState]);
  const connectedDeviceIdRef = useRef<string | null>(null);
  const discoverySubRef = useRef<any>(null);
  const connectSubRef = useRef<any>(null);
  const disconnectSubRef = useRef<any>(null);

  const loadCampaigns = useCallback(
    async (isRefresh = false) => {
      if (isRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      const trimmed = marketInput.trim();
      const marketId = trimmed.length > 0 ? parseInt(trimmed, 10) : undefined;

      const result = await CampaignService.fetchCampaigns({
        market: typeof marketId === 'number' && !Number.isNaN(marketId) ? marketId : undefined,
        active: activeOnly ? true : undefined,
      });

      setCampaigns(result);
      setHasSearched(true);
      // A 0-length result is shown as an empty state, not an error.
      setLoading(false);
      setRefreshing(false);
    },
    [marketInput, activeOnly]
  );

  // Apply: dismiss the keyboard, then run the search.
  const handleApply = () => {
    Keyboard.dismiss();
    loadCampaigns();
  };

  // --- Minimal debug display connection ---------------------------------
  // Set up our own lightweight listeners on mount; tear them down on unmount.
  // These deliberately do NONE of HomeScreen's production side effects.
  useEffect(() => {
    discoverySubRef.current = DisplayManager.onDeviceDiscovered((event: any) => {
      const devices = event?.devices || [];
      // Only react while WE initiated a scan (the continuous impression scan,
      // if running, also fires this event).
      if (connStateRef.current !== 'scanning') return;
      if (devices.length > 0) {
        connectToDevice(devices[0].id);
      } else {
        setConnState('disconnected');
        Alert.alert('Display not found', 'No Mobill display was found. Make sure it is powered on and nearby.');
      }
    });

    connectSubRef.current = DisplayManager.onDeviceConnected(async (event: any) => {
      console.log('🐞 DebugScreen: device connected', event?.id);
      connectedDeviceIdRef.current = event?.id || connectedDeviceIdRef.current;
      setConnState('connected');
      // Power the panel on, then immediately send the selected ad.
      try {
        await DisplayManager.turnOnDisplay();
      } catch (error) {
        console.error('🐞 DebugScreen: turnOn after connect failed', error);
      }
      sendAdRef.current?.(false);
    });

    disconnectSubRef.current = DisplayManager.onDeviceDisconnected(() => {
      console.log('🐞 DebugScreen: device disconnected');
      connectedDeviceIdRef.current = null;
      setConnState('disconnected');
    });

    return () => {
      discoverySubRef.current?.remove?.();
      connectSubRef.current?.remove?.();
      disconnectSubRef.current?.remove?.();
      // Tear down any debug-initiated connection so it doesn't linger and
      // conflict with HomeScreen's connection management after we leave.
      const id = connectedDeviceIdRef.current;
      if (id) {
        DisplayManager.disconnectDevice(id).catch(() => {});
      }
    };
    // Mount-once: the discovery handler reads connStateRef, not connState.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const requestBluetoothPermissions = async (): Promise<boolean> => {
    if (Platform.OS !== 'android') return true;
    try {
      const apiLevel = Platform.Version as number;
      if (apiLevel >= 31) {
        const results = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        ]);
        return (
          results[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN] === PermissionsAndroid.RESULTS.GRANTED &&
          results[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT] === PermissionsAndroid.RESULTS.GRANTED
        );
      }
      const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION);
      return granted === PermissionsAndroid.RESULTS.GRANTED;
    } catch (error) {
      console.error('🐞 DebugScreen: BT permission error', error);
      return false;
    }
  };

  const connectToDevice = async (deviceId: string) => {
    try {
      setConnState('connecting');
      const success = await DisplayManager.connectToDevice(deviceId);
      if (!success) {
        setConnState('disconnected');
        Alert.alert('Connection failed', 'Could not connect to the display. Please try again.');
      }
      // success → onDeviceConnected sets state to 'connected'
    } catch (error) {
      setConnState('disconnected');
      Alert.alert('Connection error', `${error}`);
    }
  };

  const handleConnect = async () => {
    // Connecting also sends the selected ad, so require content first.
    if (!content) {
      Alert.alert('No ad content', 'Select a campaign with ad content before connecting.');
      return;
    }
    try {
      const hasPerms = await requestBluetoothPermissions();
      if (!hasPerms) {
        Alert.alert('Bluetooth permission required', 'Grant Bluetooth permissions to connect to the display.');
        return;
      }

      const btState: any = await DisplayManager.checkBluetoothState();
      if (btState && btState.available === false) {
        Alert.alert('Bluetooth not available', 'This device has no usable Bluetooth.');
        return;
      }
      if (btState && !btState.enabled) {
        Alert.alert('Bluetooth disabled', 'Enable Bluetooth, then try again.');
        return;
      }

      setConnState('scanning');
      const started = await DisplayManager.startScan();
      if (!started) {
        setConnState('disconnected');
        Alert.alert('Scan failed', 'Failed to start scanning. Check Bluetooth permissions.');
      }
      // Native fires onDeviceDiscovered (or empty list) after its 10s timeout.
    } catch (error) {
      setConnState('disconnected');
      Alert.alert('Error', `Failed to start scan: ${error}`);
    }
  };

  const handleDisconnect = async () => {
    const id = connectedDeviceIdRef.current;
    try {
      // Power the panel off before dropping the link (same effect as the home
      // screen's off button), then disconnect.
      try {
        await DisplayManager.turnOffDisplay();
      } catch (error) {
        console.error('🐞 DebugScreen: turnOff before disconnect failed', error);
      }
      if (id) await DisplayManager.disconnectDevice(id);
    } catch (error) {
      console.error('🐞 DebugScreen: disconnect error', error);
    } finally {
      connectedDeviceIdRef.current = null;
      setConnState('disconnected');
    }
  };

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return campaigns;
    return campaigns.filter((c) => {
      const haystack = [
        c.ad ?? '',
        c.description ?? '',
        c.market ?? '',
        String(c.id),
      ]
        .join(' ')
        .toLowerCase();
      return haystack.includes(q);
    });
  }, [campaigns, search]);

  const openDetail = (campaign: CampaignListItem) => {
    setSelected(campaign);
    setContent(null);
    setContentError(false);
    setView('detail');
    loadContent(campaign.id);
  };

  const backToList = () => {
    setSelected(null);
    setContent(null);
    setContentError(false);
    setView('list');
  };

  const loadContent = useCallback(async (id: string) => {
    setContentLoading(true);
    setContentError(false);
    const result = await CampaignService.fetchCampaignContent(id);
    setContent(result);
    setContentError(result === null);
    setContentLoading(false);
  }, []);

  // Send the currently selected ad to the connected display. Used both by the
  // auto-send on connect and the manual "Resend ad" button. Reads contentRef so
  // the mount-once connect listener always sends the latest selection.
  const sendAd = useCallback(async (showAlerts = true) => {
    const c = contentRef.current;
    if (!c) {
      if (showAlerts) Alert.alert('No ad content', 'This campaign has no ad content to send.');
      return;
    }
    setSending(true);
    try {
      const config = buildDisplayConfig(c);
      const success = await DisplayManager.displayContent(config);
      if (!success && showAlerts) {
        Alert.alert('Send failed', 'The ad could not be sent to the display.');
      }
    } catch (error) {
      console.error('🐞 DebugScreen: send failed:', error);
      if (showAlerts) Alert.alert('Send error', `${error}`);
    } finally {
      setSending(false);
    }
  }, []);
  useEffect(() => {
    sendAdRef.current = sendAd;
  }, [sendAd]);

  // ---- List view --------------------------------------------------------

  const renderListItem = ({ item }: { item: CampaignListItem }) => (
    <TouchableOpacity style={styles.card} onPress={() => openDetail(item)} activeOpacity={0.7}>
      <View style={styles.cardHeader}>
        <Text style={styles.cardTitle} numberOfLines={1}>
          {item.ad || '(no ad name)'}
        </Text>
        <View style={[styles.badge, item.active ? styles.badgeActive : styles.badgeInactive]}>
          <Text style={styles.badgeText}>{item.active ? 'ACTIVE' : 'INACTIVE'}</Text>
        </View>
      </View>
      <Text style={styles.cardSubtitle} numberOfLines={1}>
        #{item.id} • {item.market || 'no market'}
      </Text>
      <Text style={styles.cardMeta}>
        Spots today {item.today_spots} / total {item.total_spots}
      </Text>
    </TouchableOpacity>
  );

  const renderList = () => (
    <>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>🐞 Debug · Campaigns</Text>
        <TouchableOpacity onPress={onClose} style={styles.closeButton}>
          <Text style={styles.closeButtonText}>Close</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.filtersRow}>
        <TextInput
          style={styles.marketInput}
          placeholder="Market ID"
          placeholderTextColor="#777"
          keyboardType="number-pad"
          value={marketInput}
          onChangeText={setMarketInput}
        />
        <View style={styles.activeToggle}>
          <Text style={styles.toggleLabel}>Active only</Text>
          <Switch
            value={activeOnly}
            onValueChange={setActiveOnly}
            trackColor={{ false: '#444', true: '#1B46F5' }}
            thumbColor="#FFFFFF"
          />
        </View>
        <TouchableOpacity style={styles.applyButton} onPress={handleApply}>
          <Text style={styles.applyButtonText}>Apply</Text>
        </TouchableOpacity>
      </View>

      <TextInput
        style={styles.searchInput}
        placeholder="Search ad / description / market / id"
        placeholderTextColor="#777"
        value={search}
        onChangeText={setSearch}
        autoCorrect={false}
        autoCapitalize="none"
      />

      {loading ? (
        <View style={styles.centerFill}>
          <ActivityIndicator size="large" color="#4A90E2" />
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(item) => String(item.id)}
          renderItem={renderListItem}
          contentContainerStyle={styles.listContent}
          refreshing={refreshing}
          onRefresh={() => loadCampaigns(true)}
          ListEmptyComponent={
            <View style={styles.centerFill}>
              {hasSearched ? (
                <>
                  <Text style={styles.emptyText}>No campaigns found.</Text>
                  <Text style={styles.emptyHint}>
                    Pull to refresh, adjust filters, or check your connection.
                  </Text>
                </>
              ) : (
                <>
                  <Text style={styles.emptyText}>Tap Apply to load campaigns.</Text>
                  <Text style={styles.emptyHint}>
                    Optionally set a Market ID or toggle Active first.
                  </Text>
                </>
              )}
            </View>
          }
        />
      )}
    </>
  );

  // ---- Detail view ------------------------------------------------------

  const renderDetailRow = (label: string, value: string | number | null | undefined) => (
    <View style={styles.detailRow} key={label}>
      <Text style={styles.detailLabel}>{label}</Text>
      <Text style={styles.detailValue}>
        {value === null || value === undefined || value === '' ? '—' : String(value)}
      </Text>
    </View>
  );

  const renderContentPreview = (c: AdContent) => {
    const isTextOnly = c.programType === 'text';
    const hasImage = !!c.contentUrl && c.programType !== 'text';
    const aspect =
      c.displaySize && c.displaySize.height > 0
        ? c.displaySize.width / c.displaySize.height
        : undefined;

    return (
      <View style={styles.previewCard}>
        {hasImage ? (
          <Image
            source={{ uri: c.contentUrl }}
            style={[styles.previewImage, aspect ? { aspectRatio: aspect } : null]}
            resizeMode="contain"
          />
        ) : null}

        {(isTextOnly || c.programType === 'mixed') && c.textContent ? (
          <View style={styles.textPreview}>
            <Text style={[styles.textPreviewText, { color: toCssColor(c.textColor) }]}>
              {c.textContent}
            </Text>
          </View>
        ) : null}

        <View style={styles.previewMeta}>
          {renderDetailRow('Type', c.programType)}
          {renderDetailRow('Size', `${c.displaySize?.width}×${c.displaySize?.height}`)}
          {c.contentUrl ? renderDetailRow('URL', c.contentUrl) : null}
          {c.textContent ? renderDetailRow('Text', c.textContent) : null}
          {c.textColor ? renderDetailRow('Color', c.textColor) : null}
          {c.templateMode ? renderDetailRow('Template', c.templateMode) : null}
          {renderDetailRow('Mode', c.mode)}
          {renderDetailRow('Speed', c.speed)}
          {renderDetailRow('Stay time', c.stayTime)}
        </View>
      </View>
    );
  };

  const renderPlaybackControls = () => {
    const busy = connState === 'scanning' || connState === 'connecting';
    const connected = connState === 'connected';

    if (busy) {
      return (
        <View style={[styles.connectButton, styles.playButtonDisabled]}>
          <ActivityIndicator color="#FFFFFF" size="small" />
        </View>
      );
    }

    if (connected) {
      return (
        <TouchableOpacity
          style={[styles.connectButton, styles.stopButton, sending && styles.playButtonDisabled]}
          onPress={handleDisconnect}
          disabled={sending}
          activeOpacity={0.8}
        >
          <Text style={styles.connectButtonText}>Disconnect</Text>
        </TouchableOpacity>
      );
    }

    // Disconnected: connecting also sends the selected ad.
    return (
      <TouchableOpacity
        style={[styles.connectButton, !content && styles.playButtonDisabled]}
        onPress={handleConnect}
        disabled={!content}
        activeOpacity={0.8}
      >
        <Text style={styles.connectButtonText}>Connect &amp; send ad</Text>
      </TouchableOpacity>
    );
  };

  const renderDetail = () => {
    if (!selected) return null;
    return (
      <>
        <View style={styles.header}>
          <TouchableOpacity onPress={backToList} style={styles.closeButton}>
            <Text style={styles.closeButtonText}>‹ Back</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle} numberOfLines={1}>
            Campaign #{selected.id}
          </Text>
          <View style={styles.closeButton} />
        </View>

        <ScrollView contentContainerStyle={styles.detailContent}>
          <Text style={styles.detailHeading}>{selected.ad || '(no ad name)'}</Text>

          {/* Playback — full-width horizontal card */}
          <Text style={styles.sectionLabel}>Playback</Text>
          <View style={styles.playbackCard}>
            <View style={styles.playbackRow}>
              <Text style={styles.playbackStatus}>
                {connState === 'connected'
                  ? 'Connected'
                  : connState === 'scanning'
                    ? 'Scanning…'
                    : connState === 'connecting'
                      ? 'Connecting…'
                      : 'Disconnected'}
              </Text>
              <View style={styles.playbackButtonWrap}>{renderPlaybackControls()}</View>
            </View>
            <Text style={styles.playbackNote}>
              Connecting powers on the display and sends this ad. Disconnect turns
              the display off.
            </Text>
          </View>

          {/* Ad content — full-width card below */}
          <Text style={styles.sectionLabel}>Ad content</Text>
          {contentLoading ? (
            <View style={styles.previewCard}>
              <ActivityIndicator color="#4A90E2" />
            </View>
          ) : contentError || !content ? (
            <View style={styles.previewCard}>
              <Text style={styles.playbackNote}>
                No ad content available for this campaign.
              </Text>
            </View>
          ) : (
            renderContentPreview(content)
          )}

          {/* Campaign metadata */}
          <Text style={styles.sectionLabel}>Campaign</Text>
          <View style={styles.detailCard}>
            {renderDetailRow('ID', selected.id)}
            {renderDetailRow('Market', selected.market)}
            {renderDetailRow('Active', selected.active ? 'Yes' : 'No')}
            {renderDetailRow('Description', selected.description)}
            {renderDetailRow('Start', selected.start)}
            {renderDetailRow('Duration (days)', selected.duration)}
            {renderDetailRow('End date', selected.end_date)}
          </View>

          <Text style={styles.sectionLabel}>Spots & budget</Text>
          <View style={styles.detailCard}>
            {renderDetailRow('Today spots', selected.today_spots)}
            {renderDetailRow('Total spots', selected.total_spots)}
            {renderDetailRow('Daily budget', selected.daily_budget)}
            {renderDetailRow('Daily budget spent', selected.daily_budget_spent)}
            {renderDetailRow('Total budget spent', selected.total_budget_spent)}
          </View>
        </ScrollView>
      </>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#131313" />
      {view === 'list' ? renderList() : renderDetail()}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#131313',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#2A2A2A',
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: 'bold',
    flex: 1,
    textAlign: 'center',
  },
  closeButton: {
    minWidth: 60,
    paddingVertical: 6,
  },
  closeButtonText: {
    color: '#4A90E2',
    fontSize: 16,
    fontWeight: '600',
  },
  filtersRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  marketInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: '#FFFFFF',
    fontSize: 14,
    width: 100,
    borderWidth: 1,
    borderColor: '#333',
  },
  activeToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  toggleLabel: {
    color: '#CCCCCC',
    fontSize: 14,
    marginRight: 8,
  },
  applyButton: {
    backgroundColor: '#1B46F5',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 9,
  },
  applyButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  searchInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 8,
    marginHorizontal: 16,
    marginTop: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: '#FFFFFF',
    fontSize: 14,
    borderWidth: 1,
    borderColor: '#333',
  },
  listContent: {
    padding: 16,
    flexGrow: 1,
  },
  card: {
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 10,
    padding: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#2A2A2A',
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  cardTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    flex: 1,
    marginRight: 8,
  },
  cardSubtitle: {
    color: '#AAAAAA',
    fontSize: 13,
    marginTop: 4,
  },
  cardMeta: {
    color: '#888888',
    fontSize: 12,
    marginTop: 6,
  },
  badge: {
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  badgeActive: {
    backgroundColor: 'rgba(39, 174, 96, 0.2)',
    borderWidth: 1,
    borderColor: '#27AE60',
  },
  badgeInactive: {
    backgroundColor: 'rgba(153,153,153,0.15)',
    borderWidth: 1,
    borderColor: '#666',
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontWeight: 'bold',
  },
  centerFill: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    color: '#CCCCCC',
    fontSize: 16,
    fontWeight: '600',
  },
  emptyHint: {
    color: '#888888',
    fontSize: 13,
    marginTop: 6,
    textAlign: 'center',
    paddingHorizontal: 40,
  },
  detailContent: {
    padding: 16,
  },
  detailHeading: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  sectionLabel: {
    color: '#4A90E2',
    fontSize: 13,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginTop: 20,
    marginBottom: 8,
  },
  detailCard: {
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 10,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: '#2A2A2A',
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 11,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#2A2A2A',
  },
  detailLabel: {
    color: '#999999',
    fontSize: 14,
    flex: 1,
  },
  detailValue: {
    color: '#FFFFFF',
    fontSize: 14,
    flex: 1.4,
    textAlign: 'right',
  },
  playbackRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  playbackStatus: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  playbackButtonWrap: {
    minWidth: 150,
  },
  connectButton: {
    backgroundColor: '#1B46F5',
    borderRadius: 8,
    paddingVertical: 12,
    paddingHorizontal: 18,
    alignItems: 'center',
  },
  connectButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
  previewCard: {
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#2A2A2A',
    alignItems: 'center',
  },
  previewImage: {
    width: '100%',
    height: undefined,
    aspectRatio: 5, // overridden per-content when displaySize is known
    backgroundColor: '#000000',
    borderRadius: 6,
    marginBottom: 12,
  },
  textPreview: {
    width: '100%',
    backgroundColor: '#000000',
    borderRadius: 6,
    paddingVertical: 20,
    paddingHorizontal: 12,
    alignItems: 'center',
    marginBottom: 12,
  },
  textPreviewText: {
    fontSize: 22,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  previewMeta: {
    width: '100%',
  },
  playbackCard: {
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: '#2A2A2A',
  },
  stopButton: {
    backgroundColor: '#C0392B',
  },
  playButtonDisabled: {
    opacity: 0.4,
  },
  playbackNote: {
    color: '#888888',
    fontSize: 12,
    marginTop: 12,
    lineHeight: 17,
  },
});

export default DebugScreen;
