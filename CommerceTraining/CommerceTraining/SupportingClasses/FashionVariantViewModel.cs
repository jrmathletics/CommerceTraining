using EPiServer.Core;
using Mediachase.Commerce.Catalog.Objects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CommerceTraining.SupportingClasses
{
    public class FashionVariantViewModel
    {
        public string Code { get; set; }

        public Price discountPrice { get; set; }
        public string priceString { get; set; }
        public string image { get; set; }
        public string name { get; set; }
        public string url { get; set; }
        public bool CanBeMonogrammed { get; set; }
        public XhtmlString MainBody { get; set; }

        public string CartUrl { get; set; }
        public string WishlistUrl { get; set; }
    }
}