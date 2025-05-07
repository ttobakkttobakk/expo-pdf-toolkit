export type PDFToolkitModuleEvents = {
  onProgress: (event: {
    progress: number;
    page: number;
    total: number;
  }) => void;
};
