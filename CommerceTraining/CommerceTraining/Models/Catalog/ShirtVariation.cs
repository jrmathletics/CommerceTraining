using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Commerce.Catalog.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAnnotations;
using Mediachase.Commerce.Security;

namespace CommerceTraining.Models.Catalog
{
    [CatalogContentType(DisplayName = "Shirt variation", GUID = "0A33352D-4F25-4DFE-AFF5-8CA9F5781528", Description = "", MetaClassName = "Shirt_Variation")]
    public class ShirtVariation : VariationContent
    {
        [CultureSpecific]
        [IncludeInDefaultSearch]
        [Searchable]
        [Tokenize]
        public virtual XhtmlString MainBody { get; set; }

        [IncludeInDefaultSearch]
        public virtual string Size { get; set; }

        [IncludeInDefaultSearch]
        public virtual string Color { get; set; }

        public virtual bool CanBeMonogrammed { get; set; }

        [Searchable]
        [Tokenize]
        [IncludeInDefaultSearch]
        [IncludeValuesInSearchResults]
        public virtual string ThematicTag { get; set; }
    }
}