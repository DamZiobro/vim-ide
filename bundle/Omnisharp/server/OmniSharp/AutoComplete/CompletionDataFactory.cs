using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Completion;
using ICSharpCode.NRefactory.Completion;
using ICSharpCode.NRefactory.TypeSystem;
using OmniSharp.Documentation;
using OmniSharp.Solution;

namespace OmniSharp.AutoComplete
{
    public class CompletionDataFactory : ICompletionDataFactory
    {
        private readonly string _partialWord;
        private readonly bool _instantiating;
        private readonly CSharpAmbience _ambience = new CSharpAmbience { ConversionFlags = AmbienceFlags };
        private readonly CSharpAmbience _signatureAmbience = new CSharpAmbience { ConversionFlags = AmbienceFlags | ConversionFlags.ShowReturnType };

        private const ConversionFlags AmbienceFlags =
            ConversionFlags.ShowParameterList |
            ConversionFlags.ShowParameterNames;

        private string _completionText;
        private string _signature;
        private readonly bool _wantDocumentation;
        private readonly IProject _project;

        public CompletionDataFactory(IProject project, string partialWord, bool instantiating, bool wantDocumentation)
        {
            _project = project;
            _partialWord = partialWord;
            _instantiating = instantiating;
            _wantDocumentation = wantDocumentation;
        }

        public ICompletionData CreateEntityCompletionData(IEntity entity)
        {

            _completionText = _signature = entity.Name;

            _completionText = _ambience.ConvertEntity(entity).Replace(";", "");
            if (!_completionText.IsValidCompletionFor(_partialWord))
                return new CompletionData("~~");

            if (entity is IMethod)
            {
                var method = entity as IMethod;
                GenerateMethodSignature(method);
            }

            if (entity is IField || entity is IProperty)
            {
                _signature = _signatureAmbience.ConvertEntity(entity).Replace(";", "");
            }

            ICompletionData completionData = CompletionData(entity);

            Debug.Assert(completionData != null);
            return completionData;
        }

        private ICompletionData CompletionData(IEntity entity)
        {

            ICompletionData completionData = null;
            if (entity.Documentation != null)
            {
                completionData = new CompletionData(_signature, _completionText,
                                                    _signature + Environment.NewLine +
                                                    DocumentationConverter.ConvertDocumentation(entity.Documentation));
            }
            else
            {

                var ambience = new CSharpAmbience
                {
                    ConversionFlags = ConversionFlags.ShowParameterList |
                                      ConversionFlags.ShowParameterNames |
                                      ConversionFlags.ShowReturnType |
                                      ConversionFlags.ShowBody |
                                      ConversionFlags.ShowTypeParameterList
                };

                var documentationSignature = ambience.ConvertEntity(entity);
                if (_wantDocumentation)
                {
                    string documentation = new DocumentationFetcher().GetDocumentation(_project, entity);
                    var documentationAndSignature =
                        documentationSignature + Environment.NewLine + documentation;
                    completionData = new CompletionData(_signature, _completionText, documentationAndSignature);
                }
                else
                {
                    completionData = new CompletionData(_signature, _completionText, documentationSignature);
                }
            }
            return completionData;
        }

        private void GenerateMethodSignature(IMethod method)
        {
            _signature = _signatureAmbience.ConvertEntity(method).Replace(";", "");
            _completionText = _ambience.ConvertEntity(method);
            _completionText = _completionText.Remove(_completionText.IndexOf('(') + 1);
            var zeroParameterCount = method.IsExtensionMethod ? 1 : 0;
            if (method.Parameters.Count == zeroParameterCount)
            {
                _completionText += ")";
            }
        }

        private void GenerateGenericMethodSignature(IMethod method)
        {
            _signature = _signatureAmbience.ConvertEntity(method).Replace(";", "");
            _completionText = _ambience.ConvertEntity(method);
            _completionText = _completionText.Remove(_completionText.IndexOf('(')) + "<";
        }

        public ICompletionData CreateEntityCompletionData(IEntity entity, string text)
        {
            return new CompletionData(text);
        }

        public ICompletionData CreateTypeCompletionData(IType type, bool showFullName, bool isInAttributeContext)
        {
            if (!type.Name.IsValidCompletionFor(_partialWord))
            {
                return new CompletionData("~~");
            }
            var completion = new CompletionData(type.Name);
            if (_instantiating)
            {
                foreach (var constructor in type.GetConstructors())
                {
                    if (type.TypeParameterCount > 0)
                    {
                        GenerateGenericMethodSignature(constructor);
                        ICompletionData completionData = CompletionData(constructor);
                        completion.AddOverload(completionData);
                    }
                    else
                    {
                        completion.AddOverload(CreateEntityCompletionData(constructor));
                    }
                }
            }
            else
            {
                completion.AddOverload(completion);
            }
            return completion;
        }

        public ICompletionData CreateMemberCompletionData(IType type, IEntity member)
        {
            return new CompletionData(type.Name);
        }

        public ICompletionData CreateLiteralCompletionData(string title, string description, string insertText)
        {
            return new CompletionData(title, description);
        }

        public ICompletionData CreateNamespaceCompletionData(INamespace name)
        {
            return new CompletionData(name.Name, name.FullName);
        }

        public ICompletionData CreateVariableCompletionData(IVariable variable)
        {
            return new CompletionData(variable.Name);
        }

        public ICompletionData CreateVariableCompletionData(ITypeParameter parameter)
        {
            return new CompletionData(parameter.Name);
        }

        public ICompletionData CreateEventCreationCompletionData(string varName, IType delegateType, IEvent evt,
                                                                 string parameterDefinition,
                                                                 IUnresolvedMember currentMember,
                                                                 IUnresolvedTypeDefinition currentType)
        {
            return new CompletionData(varName);
        }

        public ICompletionData CreateNewOverrideCompletionData(int declarationBegin, IUnresolvedTypeDefinition type,
                                                               IMember m)
        {
            return new CompletionData(m.Name);
        }

        public ICompletionData CreateNewPartialCompletionData(int declarationBegin, IUnresolvedTypeDefinition type,
                                                              IUnresolvedMember m)
        {
            return new CompletionData(m.Name);
        }

        public IEnumerable<ICompletionData> CreateCodeTemplateCompletionData()
        {
            return Enumerable.Empty<ICompletionData>();
        }

        public IEnumerable<ICompletionData> CreatePreProcessorDefinesCompletionData()
        {
            yield return new CompletionData("DEBUG");
            yield return new CompletionData("TEST");
        }

        public ICompletionData CreateImportCompletionData(IType type, bool useFullName)
        {
            throw new NotImplementedException();
        }
    }
}
