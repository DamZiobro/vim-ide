namespace OmniSharp.Rename
{
    public class ModifiedFileResponse
    {
        public ModifiedFileResponse() {}

        public ModifiedFileResponse(string fileName, string buffer) {
            this.FileName = fileName;
            this.Buffer = buffer;
        }

        public string FileName { get; set; }
        public string Buffer { get; set; }

    }
}
