import {Command, Flags} from '@oclif/core';
import * as fs from 'fs';
import * as path from 'path';

import {SERVER_CONFIG_BASEPATH} from '../constants/paths';
import {RepackageService} from '../services/repackage.service';
import {ServerConfig} from '../util/types';

/**
 * Oc repackage command for funbucks
 */
export default class Oc extends Command {
  static description = 'repackage fluentbit configuration for OC';

  static examples = [
    '<%= config.bin %> <%= command.id %>',
  ];

  static flags = {
    server: Flags.string({char: 's', required: true, description: 'server to render the config for'}),
  };

  /**
   * Generate command
   */
  public async run(): Promise<void> {
    const {flags} = await this.parse(Oc);
    const serverConfigStr = fs.readFileSync(path.resolve(SERVER_CONFIG_BASEPATH, `${flags.server}.json`), 'utf8');
    const serverConfig: ServerConfig = JSON.parse(serverConfigStr);
    const service: RepackageService = new RepackageService();

    // Tidy up from previous runs
    await RepackageService.clean();
    await service.package(serverConfig);
  }
}
