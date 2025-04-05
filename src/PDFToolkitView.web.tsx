import * as React from 'react';

import { PDFToolkitViewProps } from './PDFToolkit.types';

export default function PDFToolkitView(props: PDFToolkitViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
