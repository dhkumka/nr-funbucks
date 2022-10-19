import * as util from 'util';
import * as fs from 'fs';
import * as path from 'path';
import {stringify} from 'yaml';

const readdir = util.promisify(fs.readdir);
const stat = util.promisify(fs.stat);

import {OUTPUT_BASEPATH, REPACKAGE_BASEPATH} from '../constants/paths';
import {ServerConfig} from '../util/types';

interface Outpath {
  file: string;
  key: string;
  confPath: string;
}

interface ConfigMapData {
  [key: string]: string
}

export class RepackageService {
  /**
   * Cleans output path
   * @returns Promise resolved when everything cleaned
   */
  public static clean(): Promise<void> {
    fs.rmSync(REPACKAGE_BASEPATH, {recursive: true, force: true});
    fs.mkdirSync(REPACKAGE_BASEPATH);
    return Promise.resolve();
  }

  public async package(serverConfig: ServerConfig): Promise<void> {
    const files = (await this.getFiles(OUTPUT_BASEPATH))
      .map((file) => ({
        file,
        key: file.substring(OUTPUT_BASEPATH.length + 1).replaceAll(/\//g, '_'),
        confPath: file.substring(OUTPUT_BASEPATH.length + 1)}),
      );

    this.generateVolume(serverConfig, files);
    this.generateConfigMap(serverConfig, files);
    return Promise.resolve();
  }

  public generateVolume(serverConfig: ServerConfig, outpaths: Outpath[]) {
    const indent = serverConfig.oc?.volume.indent ? serverConfig.oc?.volume.indent : 0;
    const indentStr = ' '.repeat(indent);
    const text = stringify({
      volumes: [{
        name: 'fluentbit-config',
        configMap: {
          name: 'fluentbit-config',
          items: outpaths.map((outpath) => {
            return {
              key: outpath.key,
              path: outpath.confPath,
            };
          }),
          defaultMode: 420,
        },
      }],
    });
    fs.writeFileSync(
      path.resolve(REPACKAGE_BASEPATH, 'fluentbit-volume.yaml'),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      text.replaceAll(/^/gm, indentStr),
    );
  }

  public generateConfigMap(serverConfig: ServerConfig, outpaths: Outpath[]) {
    const initialVal: ConfigMapData = {};
    const prefix = serverConfig.oc?.configmap.prefix ? serverConfig.oc?.configmap.prefix : '';
    const suffix = serverConfig.oc?.configmap.suffix ? serverConfig.oc?.configmap.suffix : '';

    const text = stringify({
      apiVersion: 'v1',
      kind: 'ConfigMap',
      metadata: {
        name: 'fluentbit-config',
        ...(serverConfig.oc ? serverConfig.oc.configmap.metadata : {}),
      },
      data: outpaths.map((outpath) => {
        return {
          key: outpath.key,
          value: fs.readFileSync(outpath.file, 'utf8'),
        };
      }).reduce((obj, val) => {
        return {
          ...obj,
          [val.key]: val.value,
        };
      }, initialVal),
    });
    fs.writeFileSync(
      path.resolve(REPACKAGE_BASEPATH, 'fluentbit-configmap.yaml'),
      prefix + text + suffix);
  }

  public async getFiles(dir: string): Promise<string[]> {
    const subdirs = await readdir(dir);
    const files = await Promise.all(subdirs.map(async (subdir) => {
      const res = path.resolve(dir, subdir);
      return (await stat(res)).isDirectory() ? this.getFiles(res) : [res];
    }));
    return files.reduce((a, f) => a.concat(f), []);
  }
}
