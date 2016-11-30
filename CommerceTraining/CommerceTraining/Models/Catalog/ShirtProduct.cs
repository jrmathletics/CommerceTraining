using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;
using EPiServer.Commerce.Catalog.ContentTypes;
using EPiServer.Commerce.Catalog.DataAnnotations;
using EPiServer.Core;
using EPiServer.DataAbstraction;
using EPiServer.DataAnnotations;
using Mediachase.Commerce.Security;

namespace CommerceTraining.Models.Catalog
{
    [CatalogContentType(DisplayName = "Shirt product", GUID = "CA3FED79-9B82-469F-AA3D-03F291F0A413", Description = "", MetaClassName = "Shirt_Product")]
    public class ShirtProduct : ProductContent
    {

        [CultureSpecific]
        [IncludeInDefaultSearch]
        [Searchable]
        [Tokenize]
        public virtual XhtmlString MainBody { get; set; }
        public virtual string ClothesType { get; set; }
        public virtual string Brand { get; set; }

    }
}