import { registerWebModule, NativeModule } from 'expo';

import { PDFToolkitModuleEvents } from './PDFToolkit.types';

class PDFToolkitModule extends NativeModule<PDFToolkitModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(PDFToolkitModule);
