using OmniSharp.Common;

namespace OmniSharp.AutoComplete
{
    public class AutoCompleteRequest : Request
    {
        private string _wordToComplete;
        public string WordToComplete {
            get {
                return _wordToComplete ?? "";
            }
            set {
                _wordToComplete = value;
            }
        }
        private bool _wantDocumentationForEveryCompletionResult = true;

        /// <summary>
        ///   Specifies whether to return the code documentation for
        ///   each and every returned autocomplete result. Defaults to
        ///   true. Can be turned off to get a small speed boost.
        /// </summary>
        public bool WantDocumentationForEveryCompletionResult {
            get { return _wantDocumentationForEveryCompletionResult; }
            set { _wantDocumentationForEveryCompletionResult = value; }
        }

    }
}
