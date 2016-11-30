using System;
using System.ComponentModel.DataAnnotations;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Commerce.Catalog.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using EPiServer.SpecializedProperties;
using Mediachase.Commerce.Security;

namespace CommerceTraining.Models.Catalog
{
    [CatalogContentType(DisplayName = "ShirtNode", GUID = "ed1bd7f4-72e1-4803-a674-c1a6bf5e9f75", Description = "", MetaClassName = "Shirt_Node")]
    public class ShirtNode : NodeContent
    {

        [CultureSpecific]
        [Display(
            Name = "Main body",
            Description = "The main body will be shown in the main content area of the page, using the XHTML-editor you can insert for example text, images and tables.",
            GroupName = SystemTabNames.Content,
            Order = 1)]
        [IncludeInDefaultSearch]
        [Searchable]
        [Tokenize]
        public virtual XhtmlString MainBody { get; set; }

    }
}