import { NativeModule, requireNativeModule } from 'expo';

import { PDFToolkitModuleEvents } from './PDFToolkit.types';

declare class PDFToolkitModule extends NativeModule<PDFToolkitModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<PDFToolkitModule>('PDFToolkit');
