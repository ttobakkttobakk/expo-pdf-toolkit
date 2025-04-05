import { requireNativeView } from 'expo';
import * as React from 'react';

import { PDFToolkitViewProps } from './PDFToolkit.types';

const NativeView: React.ComponentType<PDFToolkitViewProps> =
  requireNativeView('PDFToolkit');

export default function PDFToolkitView(props: PDFToolkitViewProps) {
  return <NativeView {...props} />;
}
