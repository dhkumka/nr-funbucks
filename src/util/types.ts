export type FB_FILE_TYPES = 'input' | 'script' | 'filter' | 'parser' | 'lua';

export interface FbFile {
  name?: string;
  tmpl: string;
  type: FB_FILE_TYPES;
}

export type MEASURE_TYPES = {
  historic: string;
  instant: string;
}

export interface TypeConfig {
  context: object;
  files: FbFile[];
  measurementType: keyof MEASURE_TYPES;
  semver?: string;
  os?: string[];
}

export interface ServerAppConfig {
  id: string;
  type: string;
  context: object;
}

export interface OpenShiftConfigMapConfig {
  metadata: object;
  prefix: string;
  suffix: string;
}

export interface OpenShiftVolumeConfig{
  indent: number;
}

export interface OpenShiftConfig {
  configmap: OpenShiftConfigMapConfig;
  volume: OpenShiftVolumeConfig;
}

export interface ServerConfig {
  address: string; // Used by pipeline
  proxy: string; // Used by pipeline
  fluentBitRelease: string; // Used by pipeline
  logsProxyDisabled?: string; // Used by pipeline
  os: string;
  apps: ServerAppConfig[];
  context: object;
  disableFluentBitMetrics: boolean;
  oc?: OpenShiftConfig;
}

export interface BaseConfig {
  context: object;
  localContextOverride: object;
  files: FbFile[];
  fluentBitRelease: string;
}
